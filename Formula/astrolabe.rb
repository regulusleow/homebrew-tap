require "json"

class Astrolabe < Formula
  desc "Runtime UI inspection for AI coding agents"
  homepage "https://github.com/regulusleow/astrolabe"
  url "https://github.com/regulusleow/astrolabe/archive/06ad8f58425453dfbbe73d8e63ff5dab178d3129.tar.gz"
  version "2.1.0"
  sha256 "f9e9f3b3bf92c92a9e067bdf02276b120db1c410ed135b033b2ad164d00afea2"
  license "Apache-2.0"

  depends_on xcode: ["15.0", :build]
  depends_on macos: :ventura
  depends_on "node@22"

  def install
    ENV.prepend_path "PATH", formula_opt_bin("node@22")
    inreplace "scripts/distribution/source-distribution-builder.mjs",
              '["build", "-c", "release", "--product", "astrolabe"]',
              '["build", "--disable-sandbox", "-c", "release", "--product", "astrolabe"]'
    system "npm", "ci"
    architecture = Hardware::CPU.arm? ? "arm64" : "x86_64"
    distribution = buildpath/"astrolabe-distribution"
    system "npm", "run", "distribution:assemble", "--",
           "--output", distribution,
           "--channel", "homebrew",
           "--architecture", architecture
    inreplace distribution/"libexec/astrolabe-launcher.mjs",
              "#!/usr/bin/env node",
              "#!#{formula_opt_bin("node@22")}/node"
    libexec.install distribution.children
    bin.install_symlink libexec/"bin/astrolabe"
  end

  def caveats
    <<~EOS
      Configure detected AI clients explicitly after installation:
        astrolabe install --all-detected

      Homebrew lifecycle operations do not modify AI-client configuration.
    EOS
  end

  test do
    ENV["HOME"] = testpath
    assert_equal version.to_s, shell_output("#{bin}/astrolabe --version").strip

    manifest = JSON.parse((libexec/"distribution-manifest.json").read)
    assert_equal version.to_s, manifest.fetch("version")
    assert_equal "homebrew", manifest.fetch("channel")
    assert_equal "darwin", manifest.fetch("platform")
    assert_equal Hardware::CPU.arm? ? "arm64" : "x86_64", manifest.fetch("architecture")

    assert_path_exists libexec/"bin/astrolabe"
    assert_path_exists libexec/"libexec/astrolabe-native"
    assert_path_exists libexec/"libexec/mcp-adapter/dist/index.js"
    assert_path_exists libexec/"skills/astrolabe/SKILL.md"
    assert_path_exists libexec/"LICENSE"
    assert_path_exists libexec/"THIRD_PARTY_NOTICES"

    doctor = JSON.parse(shell_output("#{bin}/astrolabe doctor --verbose --json"))
    assert doctor.fetch("success")
    refute_path_exists testpath/".codex/config.toml"
    refute_path_exists testpath/".config/opencode/opencode.json"
    refute_path_exists testpath/".claude.json"
    refute_path_exists testpath/".agents/skills/astrolabe"
  end
end
