require "json"

class Astrolabe < Formula
  desc "Runtime UI inspection for AI coding agents"
  homepage "https://github.com/regulusleow/astrolabe"
  url "https://github.com/regulusleow/astrolabe/archive/refs/tags/2.1.0.tar.gz"
  sha256 "ede20cacbb53ccb20886561890c15f4a932ebff90fe1680dd607de879dac6fa6"
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
