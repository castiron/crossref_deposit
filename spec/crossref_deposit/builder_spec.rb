# frozen_string_literal: true

RSpec.describe CrossrefDeposit::Builder do
  subject(:doc) { Nokogiri::XML(sample_deposit.to_xml).remove_namespaces! }

  it "declares the 5.5.0 schema namespace and version on the root" do
    root = Nokogiri::XML(sample_deposit.to_xml).root
    expect(root.name).to eq("doi_batch")
    expect(root["version"]).to eq("5.5.0")
    expect(root.namespace.href).to eq("http://www.crossref.org/schema/5.5.0")
  end

  it "builds the head from the deposit metadata" do
    expect(doc.at_xpath("//head/doi_batch_id").text).to eq("example-20260307-0001")
    expect(doc.at_xpath("//head/depositor/depositor_name").text).to eq("Example Press")
    expect(doc.at_xpath("//head/depositor/email_address").text).to eq("doi@example.com")
    expect(doc.at_xpath("//head/registrant").text).to eq("Example Press")
  end

  it "orders book_metadata children per the schema content model" do
    children = doc.xpath("//book_metadata/*").map(&:name)
    expect(children).to eq(
      %w[contributors titles edition_number publication_date isbn publisher doi_data]
    )
  end

  it "renders contributors with sequence and role" do
    first = doc.at_xpath("//contributors/person_name[1]")
    expect(first["sequence"]).to eq("first")
    expect(first["contributor_role"]).to eq("author")
    expect(first.at_xpath("given_name").text).to eq("Jane")
    expect(first.at_xpath("surname").text).to eq("Doe")
  end

  it "zero-pads month and day and orders them before year" do
    date = doc.at_xpath("//publication_date")
    expect(date["media_type"]).to eq("online")
    expect(date.xpath("*").map(&:name)).to eq(%w[month day year])
    expect(date.at_xpath("month").text).to eq("03")
    expect(date.at_xpath("day").text).to eq("15")
    expect(date.at_xpath("year").text).to eq("2026")
  end

  it "renders the isbn with its media_type and the doi_data" do
    isbn = doc.at_xpath("//isbn")
    expect(isbn.text).to eq("9780520000000")
    expect(isbn["media_type"]).to eq("electronic")
    expect(doc.at_xpath("//doi_data/doi").text).to eq("10.1525/example.1")
    expect(doc.at_xpath("//doi_data/resource").text).to eq("https://example.com/books/example")
  end

  it "emits noisbn when no isbns are given" do
    xml = sample_deposit(items: [ sample_book(isbns: [], noisbn_reason: :monograph) ]).to_xml
    parsed = Nokogiri::XML(xml).remove_namespaces!
    expect(parsed.at_xpath("//isbn")).to be_nil
    expect(parsed.at_xpath("//noisbn")["reason"]).to eq("monograph")
  end
end
