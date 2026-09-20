# frozen_string_literal: true

def indent_for_dmark(num, s)
  indent = '  ' * num
  s.lines.map { |l| indent + l }.join("\n")
end

def kramdown2dmark(s)
  document = ::Kramdown::Document.new(s, {})

  document.warnings.each do |warning|
    warn "kramdown warning: #{warning}"
  end

  document.to_nanoc_ws_dmark
end

def index?(item)
  !item.fetch(:is_hidden, false)
end

def index_rep?(rep)
  rep.raw_path.match?(/\.(html|pdf)\z/)
end
