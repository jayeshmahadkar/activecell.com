module Jekyll

  class Expert
    include Convertible

    attr_accessor :data, :content
    attr_accessor :expertData

    def initialize(site, base, dir, name)
      @site = site

      @expertData = self.read_yaml(File.join(base, dir), name)
      @expertData['content'] = markdownify(self.content)
    end

    def publish?
      @expertData['published'].nil? or @expertData['published'] != false
    end

    # Convert a Markdown string into HTML output.
    #
    # input - The Markdown String to convert.
    #
    # Returns the HTML formatted String.
    def markdownify(input)
      converter = @site.getConverterImpl(Jekyll::MarkdownConverter)
      converter.convert(input)
    end
  end

  class ExpertList
    @@experts = []

    def self.create(site)
      @@experts = []
      dir = site.config['experts_dir'] || '_experts'
      base = File.join(site.source, dir)
      return unless File.exists?(base)

      entries = Dir.chdir(base) { site.filter_entries(Dir['**/*']) }

      # Sort by file name
      entries = entries.sort
      entries.each do |f|
        expert = Expert.new(site, site.source, dir, f)
        @@experts << expert.expertData if expert.publish?
      end
    end

    def self.experts
      @@experts
    end
  end

  # Jekyll hook - the generate method is called by jekyll, and generates all of the category pages.
  class GenerateExperts < Generator
    safe true
    priority :low

    def generate(site)
      ExpertList.create(site)
    end
  end

  class ExpertListTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      @experts = ExpertList.experts
      @template_file = markup.strip
      super
    end

    def load_template(file, context)
      includes_dir = File.join(context.registers[:site].source, '_includes')

      if File.symlink?(includes_dir)
        return "Includes directory '#{includes_dir}' cannot be a symlink"
      end

      if file !~ /^[a-zA-Z0-9_\/\.-]+$/ || file =~ /\.\// || file =~ /\/\./
        return "Include file '#{file}' contains invalid characters or sequences"
      end

      Dir.chdir(includes_dir) do
        choices = Dir['**/*'].reject { |x| File.symlink?(x) }
        if choices.include?(file)
          source = File.read(file)
        else
          "Included file '#{file}' not found in _includes directory"
        end
      end

    end

    def render(context)
      template = load_template(@template_file, context)
      Liquid::Template.parse(template).render('experts' => @experts).gsub(/\t/, '')
    end
  end

end

Liquid::Template.register_tag('expertlist', Jekyll::ExpertListTag)
