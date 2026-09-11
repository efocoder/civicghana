namespace :civicroute do
  namespace :catalog do
    desc "Verify catalog relationships and active source provenance"
    task verify: :environment do
      errors = []
      errors.concat(Region.where(active: true).filter_map { |r| "Region #{r.id} has no country" unless r.country&.active? })
      errors.concat(PortalStatus.where(active: true).filter_map { |s| "Portal status #{s.id} has no active service" unless s.public_service&.active? })
      errors.concat(ServiceRule.where(active: true).filter_map { |r| "Service rule #{r.id} has no active verified source" unless r.source&.active? && r.source.verified_at.present? })
      errors.concat(ActionPath.where(active: true).filter_map { |a| "Action path #{a.id} has no active verified source" unless a.source&.active? && a.source.verified_at.present? })
      if errors.any?
        abort errors.join("\n")
      end
      puts "Catalog verification passed (#{PublicService.where(active: true).count} active services)."
    end
  end
end
