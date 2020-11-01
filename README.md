# jekyll-action
A GitHub Action to build and publish Jekyll sites to GitHub Pages

Out-of-the-box Jekyll with GitHub Pages allows you to leverage a limited, white-listed, set of gems. Complex sites requiring custom ones or non white-listed ones (AsciiDoc for intstance) used to require a continuous integration build in order to pre-process the site.

Remember that GitHub is serving your built static site, not it's sources. So when configuring GitHub Pages in your project settings, use **gh-pages branch** as a Source for GitHub Pages. If you are setting up *username*.github.io repository, you'll have to use **master branch**, so sources can be located in another orphaned branch in the repo (which you can safely mark as default after the first publication).
In addition to that default behaviour, you can configure the branch this plugin pushes into with the `target_branch`-option. Keep in mind to set the source branch accordingly at the GitHub Pages Settings page.

Note that this is a rather simple (naive maybe) Docker based action. @limjh16 has created [a JS based version of this action](https://github.com/limjh16/jekyll-action-ts) which saves the container download time and might help with non default use cases (such as but not limited to: specific package or library that is not available as a Gem).

## Usage

### Create a Jekyll site
If you repo doesn't already have one, create a new Jekyll site:  `jekyll new sample-site`. See [the Jekyll website](https://jekyllrb.com/) for more information. In this repo, we have created a site within a `sample_site` folder within the repository because the repository's main goal is not to be a website. If it was the case, we would have created the site at the root of the repository.

### Create a `Gemfile`
As you are using this action to leverage specific Gems, well, you need to declare them! In the sample below we are using [the Jekyll AsciiDoc plugin](https://github.com/asciidoctor/jekyll-asciidoc)

```Ruby
source 'https://rubygems.org'

gem 'jekyll', '~> 3.8.5'
gem 'coderay', '~> 1.1.0'

group :jekyll_plugins do
  gem 'jekyll-asciidoc', '~> 2.1.1'
end

```

### Configure your Jekyll site
Edit the configuration file of your Jekyll site (`_config.yml`) to leverage these plugins. In our sample, we want to leverage AsciiDoc so we added the following section:

```yaml
asciidoc: {}
asciidoctor:
  base_dir: :docdir
  safe: unsafe
  attributes:
    - idseparator=_
    - source-highlighter=coderay
    - icons=font
```

Note that we also renamed `index.html` to `index.adoc` and modified this file accordingly in order to leverage AsciiDoc.

### Use the action
Use the `helaili/jekyll-action@master` action in your workflow file. It needs access to a `JEKYLL_PAT` secret set with a Personal Access Token (needs ` public_repo` scope). The directory where the Jekyll site lives will be detected (based on the location of `_config.yml`) but you can also explicitly set this directory by setting the `jekyll_src` parameter (`sample_site` for us). The `SRC` environment variable is also supported for backward compatibilty but it is deprecated.
The action will search for Gemfile location. If your want to specify it explicitly (e.g. if you have multiple Gemfiles per project), you should update `gem_src` input parameter accordingly.

Use the `actions/cache` action in the workflow as well, to shorten build times and decrease load on GitHub's servers

```yaml
name: Testing the GitHub Pages publication

on:
  push

jobs:
  jekyll:
    runs-on: ubuntu-16.04
    steps:
    - uses: actions/checkout@v2

    # Use GitHub Actions' cache to shorten build times and decrease load on servers
    - uses: actions/cache@v1
      with:
        path: vendor/bundle
        key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile') }}
        restore-keys: |
          ${{ runner.os }}-gems-

    # Standard usage
    - uses:  helaili/jekyll-action@2.0.4
      env:
        JEKYLL_PAT: ${{ secrets.JEKYLL_PAT }}

    # Specify the Jekyll source location as a parameter
    - uses: helaili/jekyll-action@2.0.4
      env:
        JEKYLL_PAT: ${{ secrets.JEKYLL_PAT }}
      with:
        jekyll_src: 'sample_site'

    # Specify the target branch (optional)
    - uses: helaili/jekyll-action@2.0.4
      env:
        JEKYLL_PAT: ${{ secrets.JEKYLL_PAT }}
      with:
        target_branch: 'gh-pages'
```

Upon successful execution, the GitHub Pages publishing will happen automatically and will be listed on the *_environment_* tab of your repository.

![image](https://user-images.githubusercontent.com/2787414/51083469-31e29700-171b-11e9-8f10-8c02dd485f83.png)

Just click on the *_View deployment_* button of the `github-pages` environment to navigate to your GitHub Pages site.

![image](https://user-images.githubusercontent.com/2787414/51083411-188d1b00-171a-11e9-9a25-f8b06f33053e.png)

### Known Limitation
Publishing of the GitHub pages can fail when using the `GITHUB_TOKEN` secret as the value of the `JEKYLL_PAT` env variable, as opposed to a Personal Access Token set as a secret. But it might work too :smile:

### I have a problem
Create a `ACTIONS_STEP_DEBUG` secret with value `true` and run the workflow again. 

### Note on custom domains
If you're using a Custom Domain for your GitHub Pages site, you will need to ensure that the `CNAME` file exists in the repository root of the `main` (or `master`) branch so that it can be copied to the deployment root when your site is deployed.

If your GitHub Pages site is run off the `main` (or `master`) branch, you can modify the Custom Domain setting in the Repository Settings to automatically generate and commit the `CNAME` file.

If your GitHub Pages site is run off an _alternate_ branch, however, you will need to manually create and commit the `CNAME` file with your custom domain as its contents, otherwise the file will be committed to the deployment branch and _overwritten the next time the action is run_.
