class AssistantsController < ApplicationController
  before_action :load_case, only: %i[explain_case explain_discrepancy explain_action refine_draft]
  before_action :check_rate_limit

  def ask
    service = PublicService.find_by(slug: params[:service_slug], active: true)
    result = Ai::AnswerQuestion.call(
      question: params[:question].to_s.strip,
      service: service,
    )
    render_ai_result(result)
  end

  def explain_rule
    service = PublicService.find_by(slug: params[:service_slug], active: true)
    rule = begin
      service && ServiceRules::Resolver.call(public_service: service, rule_type: :expected_duration_days)
    rescue ServiceRules::Resolver::NotFound
      nil
    end
    result = Ai::AnswerQuestion.call(
      question: "Explain the verified service duration rule in plain language.",
      service: service,
      retrieval_query: rule && [ rule.source.provision, rule.value, rule.unit ].compact.join(" "),
      source: rule&.source
    )
    render_ai_result(result)
  end

  def explain_case
    rule_result, evidence_comparison, action_recommendation = case_results
    result = Ai::ExplainCase.call(
      case_record: @case,
      rule_result: rule_result,
      evidence_comparison: evidence_comparison,
      action_recommendation: action_recommendation,
    )
    render_ai_result(result)
  end

  def explain_action
    _rule_result, _evidence_comparison, action_recommendation = case_results
    result = Ai::ExplainAction.call(
      action_recommendation: action_recommendation,
      service: @case.public_service,
    )
    render_ai_result(result)
  end

  def explain_discrepancy
    result = Ai::ExplainDiscrepancy.call(
      case_record: @case,
      evidence_comparison: EvidenceAssessment::Compare.call(case_record: @case),
    )
    render_ai_result(result)
  end

  def refine_draft
    result = Ai::RefineDraft.call(
      draft_text: params[:draft_text].to_s,
      tone: params[:tone].to_s,
    )
    render json: {
      refined_text: result.refined_text,
      valid: result.valid,
      provider_failed: result.provider_failed
    }
  end

  private

  def load_case
    @case = Case.includes(:public_service).find(params[:case_id])
  end

  def render_ai_result(result)
    render json: {
      answer: result.answer,
      sources: result.sources.map do |source|
        { id: source.id, title: source.title, section: source.section_label, url: source.url }
      end,
      valid: result.valid,
      provider_failed: result.provider_failed
    }
  end

  def case_results
    observations = @case.case_observations.includes(:case_milestone_observations, :reported_process_step)
      .order(:observed_on, :created_at)
    latest_portal = observations.select(&:portal?).last
    rule_result = CaseAssessment::Evaluate.call(
      case_record: @case,
      assessment_date: latest_portal&.observed_on || Date.current
    )[:rule]
    evidence_comparison = EvidenceAssessment::Compare.call(case_record: @case)
    recommendation = ActionRecommendation::Evaluate.call(
      case_record: @case,
      rule_result: rule_result,
      evidence_comparison: evidence_comparison
    )
    [ rule_result, evidence_comparison, recommendation ]
  end

  def check_rate_limit
    now = Time.current.to_i
    bucket = session[:ai_rate_limit]
    bucket = { "started_at" => now, "count" => 0 } if bucket.blank? || now - bucket.fetch("started_at", now) >= 60

    if bucket.fetch("count", 0) >= 20
      render json: { error: "Rate limit exceeded. Please try again later." }, status: :too_many_requests
      return
    end

    bucket["count"] += 1
    session[:ai_rate_limit] = bucket
  end
end
