class AssistantsController < ApplicationController
  before_action :load_case, only: %i[explain_case explain_discrepancy explain_action refine_draft]
  before_action :check_rate_limit

  def ask
    question = params[:question].to_s.strip
    service = params[:service_slug].present? ? PublicService.find_by(slug: params[:service_slug]) : nil

    result = Ai::AnswerQuestion.call(question: question, service: service)

    render json: {
      answer: result.answer,
      sources: result.sources.map { |s| { id: s.id, title: s.title, section: s.section_label, url: s.url } },
      valid: result.valid
    }
  end

  def explain_case
    observations = @case.case_observations.includes(:case_milestone_observations, :reported_process_step).order(:observed_on, :created_at)
    latest_portal = observations.select(&:portal?).last

    assessment = CaseAssessment::Evaluate.call(
      case_record: @case,
      assessment_date: latest_portal&.observed_on || Date.current
    )
    rule_result = assessment[:rule]
    evidence_comparison = EvidenceAssessment::Compare.call(case_record: @case)
    action_recommendation = ActionRecommendation::Evaluate.call(
      case_record: @case,
      rule_result: rule_result,
      evidence_comparison: evidence_comparison
    )

    result = Ai::ExplainCase.call(
      case_record: @case,
      rule_result: rule_result,
      evidence_comparison: evidence_comparison,
      action_recommendation: action_recommendation
    )

    render json: {
      answer: result.answer,
      sources: result.sources.map { |s| { id: s.id, title: s.title, section: s.section_label, url: s.url } },
      valid: result.valid
    }
  end

  def explain_action
    observations = @case.case_observations.includes(:case_milestone_observations, :reported_process_step).order(:observed_on, :created_at)
    latest_portal = observations.select(&:portal?).last

    assessment = CaseAssessment::Evaluate.call(
      case_record: @case,
      assessment_date: latest_portal&.observed_on || Date.current
    )
    rule_result = assessment[:rule]
    evidence_comparison = EvidenceAssessment::Compare.call(case_record: @case)
    action_recommendation = ActionRecommendation::Evaluate.call(
      case_record: @case,
      rule_result: rule_result,
      evidence_comparison: evidence_comparison
    )

    result = Ai::ExplainAction.call(
      action_recommendation: action_recommendation,
      service: @case.public_service
    )

    render json: {
      answer: result.answer,
      sources: result.sources.map { |s| { id: s.id, title: s.title, section: s.section_label, url: s.url } },
      valid: result.valid
    }
  end

  def explain_discrepancy
    evidence_comparison = EvidenceAssessment::Compare.call(case_record: @case)
    result = Ai::ExplainDiscrepancy.call(
      case_record: @case,
      evidence_comparison: evidence_comparison
    )

    render json: {
      answer: result.answer,
      sources: result.sources.map { |s| { id: s.id, title: s.title, section: s.section_label, url: s.url } },
      valid: result.valid
    }
  end

  def refine_draft
    draft_text = params[:draft_text].to_s
    tone = params[:tone].to_s

    result = Ai::RefineDraft.call(draft_text: draft_text, tone: tone)

    render json: {
      refined_text: result.refined_text,
      valid: result.valid
    }
  end

  private

  def load_case
    @case = Case.includes(:public_service).find(params[:case_id])
  end

  def check_rate_limit
    session_key = :ai_request_count
    session[session_key] ||= 0
    session[session_key] += 1

    if session[session_key] > 20
      render json: { error: "Rate limit exceeded. Please try again later." }, status: :too_many_requests
    end
  end
end
