# frozen_string_literal: true

require "nokogiri"

module CrossrefDeposit
  # Validates deposit XML against the bundled CrossRef schema, offline.
  #
  # libxml2 (via Nokogiri) implements XSD 1.0 only, whereas the CrossRef schema
  # uses XSD 1.1 <xsd:assert> co-occurrence constraints. Those asserts are
  # removed and ignored here; they are validated by CrossRef server-side.
  class Validator
    XSD_NAMESPACE = "http://www.w3.org/2001/XMLSchema"
    COMPILE_LOCK = Mutex.new

    def initialize(schema_path: CrossrefDeposit::SCHEMA_PATH)
      @schema_path = schema_path
    end

    # @param xml [String] a doi_batch document
    # @return [Array<String>] schema error messages; empty when valid
    def validate(xml)
      schema.validate(Nokogiri::XML(xml)).map(&:message)
    end

    private

    def schema
      @schema ||= COMPILE_LOCK.synchronize { @schema || compile }
    end

    # Parses the schema with its path as base URI so relative includes resolve
    # against the vendored files, strips XSD 1.1 asserts, then compiles.
    def compile
      document = Nokogiri::XML(File.read(@schema_path), @schema_path)
      document.xpath("//xsd:assert", "xsd" => XSD_NAMESPACE).each(&:remove)
      Nokogiri::XML::Schema.from_document(document)
    end
  end
end
