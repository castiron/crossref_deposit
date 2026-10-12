# frozen_string_literal: true

require "nokogiri"

module CrossrefDeposit
  # Renders a {Deposit} to a CrossRef deposit (doi_batch) document.
  #
  # Element order follows the deposit schema's book_metadata content model,
  # which is strict: contributors, titles, edition_number, publication_date,
  # isbn/noisbn, publisher, doi_data.
  class Builder
    NAMESPACE = "http://www.crossref.org/schema/#{SCHEMA_VERSION}"
    XSI = "http://www.w3.org/2001/XMLSchema-instance"
    SCHEMA_LOCATION = "#{NAMESPACE} https://www.crossref.org/schemas/crossref#{SCHEMA_VERSION}.xsd"
    ENCODING = "UTF-8"

    attr_reader :deposit

    def initialize(deposit)
      @deposit = deposit
    end

    # @return [String]
    def to_xml
      Nokogiri::XML::Builder.new(encoding: ENCODING) do |xml|
        xml.doi_batch(root_attributes) do
          build_head(xml)
          build_body(xml)
        end
      end.to_xml
    end

    private

    def root_attributes
      {
        "version" => SCHEMA_VERSION,
        "xmlns" => NAMESPACE,
        "xmlns:xsi" => XSI,
        "xsi:schemaLocation" => SCHEMA_LOCATION
      }
    end

    def build_head(xml)
      xml.head do
        xml.doi_batch_id(deposit.doi_batch_id)
        xml.timestamp(deposit.timestamp)
        xml.depositor do
          xml.depositor_name(deposit.depositor.name)
          xml.email_address(deposit.depositor.email)
        end
        xml.registrant(deposit.registrant)
      end
    end

    def build_body(xml)
      xml.body do
        deposit.items.each { |book| build_book(xml, book) }
      end
    end

    def build_book(xml, book)
      xml.book(book_type: book.book_type.to_s) do
        xml.book_metadata(language: book.language) do
          build_contributors(xml, book.contributors)
          build_titles(xml, book)
          xml.edition_number(book.edition_number) if book.edition_number
          book.publication_dates.each { |date| build_publication_date(xml, date) }
          build_isbns(xml, book)
          build_publisher(xml, book.publisher)
          build_doi_data(xml, book)
        end
      end
    end

    def build_contributors(xml, contributors)
      return if contributors.empty?

      xml.contributors do
        contributors.each do |contributor|
          xml.person_name(sequence: contributor.sequence.to_s,
                          contributor_role: contributor.contributor_role.to_s) do
            xml.given_name(contributor.given_name) if contributor.given_name
            xml.surname(contributor.surname)
          end
        end
      end
    end

    def build_titles(xml, book)
      xml.titles do
        xml.title(book.title)
        xml.subtitle(book.subtitle) if book.subtitle
      end
    end

    def build_publication_date(xml, date)
      attributes = date.media_type ? { media_type: date.media_type.to_s } : {}
      xml.publication_date(attributes) do
        xml.month(format("%02d", date.month)) if date.month
        xml.day(format("%02d", date.day)) if date.day
        xml.year(date.year.to_s)
      end
    end

    def build_isbns(xml, book)
      if book.isbns.empty?
        xml.noisbn(reason: book.noisbn_reason.to_s)
      else
        book.isbns.each do |isbn|
          attributes = isbn.media_type ? { media_type: isbn.media_type.to_s } : {}
          xml.isbn(isbn.value, attributes)
        end
      end
    end

    def build_publisher(xml, publisher)
      xml.publisher do
        xml.publisher_name(publisher.name)
        xml.publisher_place(publisher.place) if publisher.place
      end
    end

    def build_doi_data(xml, book)
      xml.doi_data do
        xml.doi(book.doi)
        xml.resource(book.resource_url)
      end
    end
  end
end
