guard 'minitest' do
  watch(%r|^spec/(.*)_spec\.rb|)
  watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r|^models/(.*)([^/]+)\.rb|)  { |m| "spec/models/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r|^spec/helper\.rb|)         { "spec" }
end
