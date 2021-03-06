# encoding: utf-8

require 'rubygems'
require 'io/console'
require 'set'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'rdf/turtle'
require 'rdf/xsd'
include RDF
require 'securerandom'

def getRandomString()
    return SecureRandom.urlsafe_base64(5)
end

@user_agent = 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0'
def open_html(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  # http.open_timeout = 1
  # http.read_timeout = 10
  begin
    response = http.get(uri.path, 'User-Agent' => @user_agent)
    return nil if response.code == '500'
  rescue Net::OpenTimeout
    puts 'open_html: Net::OpenTimeout exception. Retrying...'
    retry
  end
  response.body
end

# Get final Url After Redirects
def getFinalUrl(url)
    return Net::HTTP.get_response(URI(url))['location']
end

def get_artwork_ids()
  artworks_ids = Set.new
  RDF::Query::Pattern.new(:s, RDF::URI.new('http://erlangen-crm.org/current/P14_carried_out_by'), :o).
      execute(RDF::Graph.load('rm_artwork_ownerships.ttl')).each do |statement|
    artworks_ids << /\d+/.match(statement.subject)[0]
  end
  puts 'IDs loaded'
  artworks_ids
end

def get_cached_artwork_page(artwork_id, language)
  IO.read("./rmgallery_site/objects/#{language}/#{artwork_id}.html")
end

@rdf_prefixes = {
    :xsd  => XSD.to_uri,
    :rdf  => RDF.to_uri,
    :rdfs => RDFS.to_uri,
    :owl  => OWL.to_uri,
    :skos  => SKOS.to_uri,
    :dc  => DC.to_uri,
    :dbp =>  "http://dbpedia.org/resource/",
    #'dbp-ru' => "http://ru.dbpedia.org/resource/",
    :ecrm => RDF::URI.new('http://erlangen-crm.org/current/'),
    :cc => RDF::URI.new('http://culturecloud.ru/resource/'),
    :cc_schema => RDF::URI.new('http://culturecloud.ru/schema/'),
}

@ecrm = RDF::Vocabulary.new(@rdf_prefixes[:ecrm]) # remove it? <- I think it is used somewhere
@ecrmVocabulary = RDF::Vocabulary.new(@rdf_prefixes[:ecrm])
@rmlodVocabulary = RDF::Vocabulary.new(@rdf_prefixes[:cc_schema])
