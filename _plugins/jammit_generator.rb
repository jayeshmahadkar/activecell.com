require "jammit"

module Jekyll
  class JammitGenerator < Generator
    safe true

    def generate(site)
      jammit_config = site.config["jammit_config"] || "_assets.yml"
      jammit_base_dir = site.config["jammit_base_dir"] || File.join(".", site.config["source"])
      jammit_output_dir = site.config["jammit_output_dir"] || "assets"

      jammit_dir = File.join(jammit_base_dir, jammit_output_dir)
      jammit_base_url = site.config["baseurl"] || "/"

      Jammit.package!(:config_path => jammit_config, :output_folder => jammit_dir, :base_url => jammit_base_url)

      (Dir.entries(jammit_dir) - [".", ".."]).each do |file|
        next if File.directory?(jammit_dir + "/" + file)
        site.static_files << StaticFile.new(site, jammit_base_dir, jammit_output_dir, file)
      end
    end
  end
end
