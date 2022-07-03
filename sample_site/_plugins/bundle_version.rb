module Jekyll

    class BundleVersionGenerator < Generator
  
      def generate(site)
        site.config['bundler_version'] = `bundle -v | cut -c 16- | xargs`.chomp
      end
  
    end
  
  end
