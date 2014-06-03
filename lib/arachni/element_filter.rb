=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# Filter for {Element elements}, used to keep track of what elements have been
# seen and separate them from new ones.
#
# Mostly used by the {Trainer}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ElementFilter
class <<self

    TYPES = [:links, :forms, :cookies]

    def reset
        @mutex = Mutex.new
        State.element_filter.clear
        nil
    end

    # @!method links
    #
    #   @return    [Support::LookUp::HashSet]

    # @!method forms
    #
    #   @return    [Support::LookUp::HashSet]

    # @!method cookies
    #
    #   @return    [Support::LookUp::HashSet]

    # @!method forms_include?( form )
    #
    #   @param    [Element::Form] form
    #
    #   @return   [Bool]

    # @!method links_include?( link )
    #
    #   @param    [Element::Link] link
    #
    #   @return   [Bool]

    # @!method cookies_include?( cookie )
    #
    #   @param    [Element::Cookie] cookie
    #
    #   @return   [Bool]

    # @!method update_links( links )
    #
    #   @param    [Array<Element::Link>] links
    #
    #   @return   [Integer]
    #       Amount of new links.

    # @!method update_forms( forms )
    #
    #   @param    [Array<Element::Form>] forms
    #
    #   @return   [Integer]
    #       Amount of new forms.

    # @!method update_cookie( cookies )
    #
    #   @param    [Array<Element::Cookie>] cookies
    #
    #   @return   [Integer]
    #       Amount of new cookies.

    TYPES.each do |type|
        define_method type do
            State.element_filter.send type
        end

        define_method "#{type}_include?" do |element|
            send(type).include? element.id
        end

        define_method "update_#{type}" do |elements|
            elements = [elements].flatten.compact
            return 0 if elements.size == 0

            synchronize do
                new_element_cnt = 0
                elements.each do |element|
                    next if send( "#{type}_include?", element )

                    send( "#{type}" ) << element.id
                    new_element_cnt += 1
                end
                new_element_cnt
            end
        end

    end

    # @param    [Element::Base] element
    #
    # @return   [Bool]
    def include?( element )
        TYPES.each do |type|
            return true if send( "#{type}_include?", element )
        end

        false
    end

    # @param    [Page]  page
    #
    # @return   [Integer]
    #   Amount of new elements.
    def update_from_page( page )
        TYPES.map { |type| send( "update_#{type}", page.send( type ) ) }.inject(&:+)
    end

    # Updates the elements from the {Page#cache}, useful in situations where
    # resources need to be preserved (thus avoiding a full page parse) and the
    # need for a full coverage update isn't vital.
    #
    # @param    [Page]  page
    #
    # @return   [Integer]
    #   Amount of new elements.
    def update_from_page_cache( page )
        TYPES.map { |type| send( "update_#{type}", page.cache[type] ) }.inject(&:+)
    end

    private

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

end

reset
end

end
