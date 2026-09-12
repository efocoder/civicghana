module Ai
  Response = Data.define(:content, :provider, :model, :input_tokens, :output_tokens, :raw_request_id)
end
