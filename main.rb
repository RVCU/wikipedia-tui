require 'wikipedia'
require 'tty-prompt'
require 'tty-pager'
require 'pandoc-ruby'
require 'tty-markdown'
require 'uri'
require 'net/http'
require 'tempfile'
require 'pry'
require 'httparty'
require 'catpix'

# Class for the wiki-term client
class WikipediaTermClient
    def initialize
        @prompt = TTY::Prompt.new
        @pager = TTY::Pager.new
        @elements = %w(summary text categories links extlinks images NewSearch)
        @browser = ENV['BROWSER']
    end


    def decide_how_to_print(wiki_page_element = @wikipedia_page.summary)
        #binding.pry
        case wiki_page_element
        when 'summary'
            print_markdown(@wikipedia_page.summary)
        when 'text'
            print_markdown(@wikipedia_page.text)
        when 'categories'
            link = @prompt.select("which category would you like to search", @wikipedia_page.categories)
            set_wiki_page(link)
        when 'links'
            link = @prompt.select("which link would you like to search", @wikipedia_page.links)
            set_wiki_page(link)
        when 'extlinks'
            link = @prompt.select("which link would you like to search", @wikipedia_page.extlinks)
            @prompt.yes?("Wanna open this link in #{@browser}?") && system("#{@browser} #{link}")
        when 'images'
            image_link = @prompt.select("images", @wikipedia_page.images)
            set_wiki_page(image_link)
            print_img_from_url(@wikipedia_page.main_image_url)
        when 'NewSearch'
            ask_for_new_wiki_page
        end
    end

    def print_markdown(markdown)
        @converter = PandocRuby.new(markdown, :from => :mediawiki, :to => :markdown)
        contents = TTY::Markdown.parse(@converter.convert)
        @pager.page(contents)
    end

    def is_ext_url(link)
        uri = URI.parse(link)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
        false
    end

    def print_img_from_url(url)
        Tempfile.create(".image", ".") do |f| 
            f.write HTTParty.get(url).body
            Catpix::print_image f.path,
                :limit_x => 0.5,
                :limit_y => 0,
                :center_x => true,
                :center_y => true,
                :bg => "grey",
                :bg_fill => false,
                :resolution => "high"
        end
    end

    def ask_for_more
        wiki_page_element = @prompt.select("More?", @elements)
        if wiki_page_element == 'New Search'
            ask_for_new_wiki_page
        else
            decide_how_to_print(wiki_page_element)
        end
    end

    def set_wiki_page(search_term)
        @wikipedia_page = Wikipedia.find(search_term) # should add check here
    end

    def ask_for_new_wiki_page
        search_term = @prompt.ask('what would you like to search?')
        set_wiki_page(search_term)
    end

    def main
        ask_for_new_wiki_page
        loop do
            ask_for_more
        end
    end
end
wiki_client = WikipediaTermClient.new
wiki_client.main
