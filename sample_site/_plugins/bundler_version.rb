module Jekyll

    class BundlerVersionGenerator < Generator
  
      def generate(site)
        site.config['bundler_version'] = `bundler -v | cut -c 16- | xargs`.chomp
      end
  
    end
  
  end
