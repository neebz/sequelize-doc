class Helpers
  require 'nokogiri'

  def self.inject_navigation(document)
    doc         = Nokogiri::HTML(document)
    navigation  = doc.at_css('.nav.dynamic')
    nav_content = ""

    doc.css('section').each do |section|
      section_name = section.at_css('h3')["data-nav-value"] || section.at_css('h3').content
      section_id   = section["id"] || (section["id"] = section_name.downcase.gsub(/\W/, '-'))

      if section.css('h4').size == 0
        nav_content += navigation_item(section_id, section_name)
      else
        sub_nav   = '<div class="subnav"><ul class="nav nav-pills">'
        sub_items = []
        nav_items = []

        section.css('h4').each do |h4|
          h4_value = h4["data-nav-value"] || h4.content
          h4_id    = "#{section_id}-#{h4_value.downcase.gsub(/\W/, '-')}"
          h4["id"] = h4_id

          nav_items << { :identifier => h4_id, :label => h4_value }
          sub_items << { :identifier => h4_id, :label => h4_value }

          if h4.parent.css('h5').size == 0
            sub_nav += navigation_item(h4_id, h4_value)
          else
            sub_items = h4.parent.css('h5').map do |h5|
              h5_value = h5["data-nav-value"] || h5.content
              h5_id    = "#{h4_id}-#{h5_value.downcase.gsub(/\W/, '-')}"
              h5["id"] = h5_id

              { :identifier => h5_id, :label => h5_value }
            end

            sub_nav += navigation_group(h4_value, sub_items)
          end
        end

        sub_nav += "</ul></div>"

        if section.css('.page-header').size != 0
          section.at_css('.page-header').inner_html += sub_nav
        end

        nav_content += navigation_group(section_name, nav_items)
      end
    end

    navigation.inner_html = nav_content

    doc.to_html
  end

private

  def self.navigation_item(identifier, label)
    "<li><a href='##{identifier}'>#{label}</a></li>"
  end

  def self.navigation_group(label, items)
    html = <<-HTML
      <li class="dropdown">
        <a class="dropdown-toggle" data-toggle="dropdown" href="#">
          #{label}
          <b class="caret"></b>
        </a>
        <ul class="dropdown-menu">
    HTML

    items.each do |item|
      html += navigation_item(item[:identifier], item[:label])
    end

    html += <<-HTML
        </ul>
      </li>
    HTML

    html
  end
end