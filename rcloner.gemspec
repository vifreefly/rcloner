require_relative 'lib/rcloner/version'

Gem::Specification.new do |spec|
  spec.name          = "rcloner"
  spec.version       = Rcloner::VERSION
  spec.authors       = ["Victor Afanasev"]
  spec.email         = ["vicfreefly@gmail.com"]

  spec.summary       = "Simple backup tool based on Rclone"
  spec.homepage      = "https://github.com/vifreefly/rcloner"
  spec.license       = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.add_dependency "thor"
  spec.add_dependency "postgressor", "~> 0.3.1"
  spec.add_dependency "dotenv"

  spec.bindir        = "exe"
  spec.executables   = "rcloner"
  spec.require_paths = ["lib"]
end
