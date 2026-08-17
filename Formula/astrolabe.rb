require "json"
require "open3"

class Astrolabe < Formula
  desc "Runtime UI inspection for AI coding agents"
  homepage "https://github.com/regulusleow/astrolabe"
  url "https://github.com/regulusleow/astrolabe/archive/refs/tags/2.2.2.tar.gz"
  sha256 "ceec971c29a109106a7dab1eb078cb4a8c91d4ff592947f5476e4ab42486223d"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/regulusleow/tap"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "9e385b6ff0c01d3ec5f6531f41bcb7a93da3671f879f7b36365fb0d71e29f488"
    sha256 cellar: :any_skip_relocation, sequoia:       "6cb1beb4094999152b3a9820a061fb579927ae70b890b21323a9ee6b6b73cdfb"
  end

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
      Configure Astrolabe for a specific AI client after installation:
        astrolabe install --client codex
        astrolabe install --client opencode
        astrolabe install --client claude-code

      Or configure every detected AI client:
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

    mcp_input = [
      {
        jsonrpc: "2.0",
        id:      1,
        method:  "initialize",
        params:  {
          protocolVersion: "2025-06-18",
          capabilities:    {},
          clientInfo:      { name: "homebrew-test", version: "1.0.0" },
        },
      },
      {
        jsonrpc: "2.0",
        method:  "notifications/initialized",
        params:  {},
      },
      {
        jsonrpc: "2.0",
        id:      2,
        method:  "tools/call",
        params:  { name: "list_apps", arguments: {} },
      },
    ].map(&:to_json).join("\n") + "\n"
    stdout, stderr, status = Open3.capture3(bin/"astrolabe", "mcp", stdin_data: mcp_input)
    assert status.success?, stderr
    responses = stdout.each_line.map { |line| JSON.parse(line) }
    tool_response = responses.find { |response| response["id"] == 2 }
    refute_nil tool_response
    assert tool_response.dig("result", "structuredContent", "success"), stdout

    refute_path_exists testpath/".codex/config.toml"
    refute_path_exists testpath/".config/opencode/opencode.json"
    refute_path_exists testpath/".claude.json"
    refute_path_exists testpath/".agents/skills/astrolabe"
  end
end
