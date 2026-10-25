# frozen_string_literal: true

################################################################################
# ENTRY POINT

def jsonld_element_for(item)
  json_ld = {
    '@context' => 'https://schema.org/',
  }.merge(jsonld_object_for(item, []))

  json_opts = {
    array_nl: "\n",
    object_nl: "\n",
    indent: '  ',
    space: ' ',
  }

  '<script type="application/ld+json">' + JSON.generate(json_ld, json_opts) + '</script>'
end

################################################################################
# JSON ID

def jsonld_id_for_web_page(item)
  category = 'WebPage'
  base_id = jsonld_base_id_for(item)

  @config[:base_url] + '/#' + category + '-' + base_id
end

def jsonld_base_id_for(item)
  Digest::SHA256.hexdigest(item.identifier.to_s)[0..20]
end

def jsonld_id_for_person
  @config[:base_url] + '/#Person'
end

def jsonld_id_for_website
  @config[:base_url] + '/#WebSite'
end

################################################################################
# OBJECTS - INDIRECT

def jsonld_object_for_website(seen)
  obj = {
    '@type' => 'WebSite',
    '@id' => jsonld_id_for_website,
  }

  if seen.include?(obj['@id'])
    return obj
  end

  seen << obj['@id']

  obj.merge(
    {
      'name' => 'Nanoc web site',
      'url' => @config[:base_url],

      'author' => jsonld_object_for_person(seen),
    },
  )
end

def jsonld_object_for_person(seen)
  obj = {
    '@type' => 'Person',
    '@id' => jsonld_id_for_person,
  }

  if seen.include?(obj['@id'])
    return obj
  end

  seen << obj['@id']

  obj.merge(
    {
      'name' => 'Denis Defreyne',
      'url' => 'https://denisdefreyne.com',
      'sameAs' => ['https://denisdefreyne.com'],
    },
  )
end

################################################################################
# OBJECTS - DIRECT

def jsonld_object_for_web_page(item, seen)
  obj = {
    '@type' => 'WebPage',
    '@id' => jsonld_id_for_web_page(item),
  }

  if seen.include?(obj['@id'])
    return obj
  end

  seen << obj['@id']

  obj.merge(
    {
      'name' => item.fetch(:full_title) { item.fetch(:title) },
    },
  )
end

def breadcrumbs_trail(item)
  components = item.identifier.components
  prefixes = components.inject(['']) { |acc, elem| acc + ["#{acc.last}/#{elem}"] }

  ancestral_prefixes = prefixes.grep_v(%r{^/index\.})[0..-2]

  ancestral_items =
    ancestral_prefixes.map do |pr|
      if pr == ''
        @items['/index.*']
      else
        @items[pr + '.*']
      end
    end

  (ancestral_items + [item]).compact
end

def jsonld_breadcrumb_for(item)
  breadcrumb_trail_items = breadcrumbs_trail(item)

  {
    '@type' => 'BreadcrumbList',
    '@id' => @config[:base_url] + item.path + '#breadcrumb',
    'itemListElement' => breadcrumb_trail_items.map.with_index do |item, index|
      {
        '@type' => 'ListItem',
        'position' => index + 1,
        'name' => item.fetch(:breadcrumb_title) { item.fetch(:full_title) { item.fetch(:title) } },
        'item' => @config[:base_url] + item.path,
      }
    end,
  }
end

def jsonld_object_for(item, seen)
  obj = jsonld_object_for_web_page(item, seen)

  defaults = {
    'author' => jsonld_object_for_person(seen),
    'url' => @config[:base_url] + item.path,
    'isPartOf' => jsonld_object_for_website(seen),
    'breadcrumb' => jsonld_breadcrumb_for(item),
  }

  if (updated_at = item[:updated_at])
    defaults['dateModified'] = extract_date(updated_at).iso8601
  end

  obj = defaults.merge(obj)
  obj.replace(obj.sort.to_h)
  obj
end
