# CrossRef Deposit

Build, validate, and submit [CrossRef](https://www.crossref.org) deposit (`doi_batch`) XML to register DOIs.

- **Build** schema-compliant `doi_batch` XML from value objects.
- **Validate** it offline against the bundled CrossRef 5.5.0 XSD
- **Submit** it over CrossRef's HTTPS deposit interface, and **fetch** the processing log once CrossRef has processed it.

**IMPORTANT NOTE:** At the moment, this gem only supports submitting entire books (of type `monograph`, `edited_book`, `reference`, or `other`).

## Installation

Add to your `Gemfile` with

```bash
bundle add crossref_deposit
```

Or install globally

```bash
gem install crossref_deposit
```

## Usage

Submitting a book happens in 3 steps:

1) Build a `Book` record containing its metadata
2) Build a `Deposit` that includes one or more `Book`s, plus registrant data
3) Instantiate a `Client` and submit the `Deposit`

All fields listed below are required, unless specifically stated as optional or as having a default.

Any attempt to initialize a model without the required parameters will raise a `CrossrefDeposit::InvalidAttributes` error.

### Create a `Book`

A `Book` contains the metadata for the item you're registering. It accepts the following keyword arguments:

* `doi`: the DOI you'd like to register
* `resource_url`: A URL to the resource
* `title`: The resource title
* `subtitle`: (Optional) The resource subtitle
* `book_type`: (Default: `:monograph`) One of `:monograph`, `:edited_book`, `:reference`, or `:other`
* `language`: (Default: `"en"`) The resource's language
* `contributors`: An array of `CrossrefDeposit::Contributor` instances
* `edition_number`: (Optional) A numeric edition number
* `publication_dates`: An array of `CrossrefDeposit::PublicationDate` instances
* `isbns`: (Optional) An array of `CrossrefDeposit::ISBN` instances
* `publisher`: A `CrossrefDeposit::Publisher` instance
* `noisbn_reason`: (Default: :monograph) If no ISBN is provided, the reason; one of `:archive_volume`, `:monograph`, or `:simple_series`

#### Contributors

Contributors are modeled as `CrossrefDeposit::Contributor`, which takes the following keyword arguments:

* `given_name`: (Optional) The contributor's given (first) name
* `surname`: The contributor's surname (last name)
* `sequence`: (Default: `:first`) The contributor order, one of `:first` or `:additional`.
* `contributor_role`: (Default: `:author`) The contributor's role, one of `:author`, `:editor`, `:chair`, `:reviewer`, `:review-assistant`, `:stats-reviewer`, `:reviewer-external`, `:reader`, `:translator`, `:corresponding-author`, `:other`.

#### Publisher

The publisher is modeled as a `CrossrefDeposit::Publisher`, which takes the following keyword arguments:

* `name`: The publisher name
* `place`: (Optional) The publisher's location

#### Publication Dates

The publication date for each media type is modeled as `CrossrefDeposit::PublicationDate`, which takes the following keyword arguments:

* `year`: The publication year
* `month`: (Optional) The publication month, 1-12
* `day`: (Optional) The publication day, 1-31
* `media_type`: (Optional) The media type that was published on this date, one of `:online`, `:print`, or `:other`.

#### ISBNs

The ISBNs are modeled as `CrossrefDeposit::ISBN`, which takes the following keyword arguments:

* `value`: The ISBN
* `media_type`: The media type represented by this ISBN, one of `:print` or `:electronic`.

#### Example

```ruby
contributors = [
  CrossrefDeposit::Contributor.new(
    given_name: "Jane",
    surname: "Doe",
    sequence: :first,
    contributor_role: :author
  ),
    CrossrefDeposit::Contributor.new(
    given_name: "John",
    surname: "Doe",
    sequence: :additional,
    contributor_role: :editor
  )
]

publisher = CrossrefDeposit::Publisher.new(
  name: "Example Press",
  place: "Exampleville, OR"
)

publication_dates = [
  CrossrefDeposit::PublicationDate.new(
    year: 2000,
    month: 1,
    day: 1,
    media_type: :print
  ),
  CrossrefDeposit::PublicationDate.new(
    year: 2012,
    month: 12,
    day: 21,
    media_type: :online
  )
]

isbns = [
  CrossrefDeposit::ISBN.new(
    value: "978-3-16-148410-0",
    media_type: :print
  ),
  CrossrefDeposit::ISBN.new(
    value: "978-3-17-193473-1",
    media_type: :electronic
  )
]

book = CrossrefDeposit::Book.new(
  doi: "10.1525/example.1",
  resource_url: "https://example.com/books/example",
  title: "An Example Monograph",
  subtitle: "A Subtitle",
  contributors: contributors,
  edition_number: 1,
  publication_dates: publication_dates,
  isbns: isbns,
  publisher: publisher
)
```

### Create the `Deposit`

A `Deposit` is the object that will be turned to XML and submitted to CrossRef. It accepts the following keyword arguments:

* `doi_batch_id`: An arbitrary, unique identifier for this submission batch
* `depositor`: A `CrossrefDeposit::Depositor` instance
* `registrant`: The name of the registrant
* `items`: An array of the books to submit
* `timestamp`: (Default: Current time) The time of submission

#### Depositor

The depositor is modeled as `CrossrefDeposit::Depositor`, which takes the following keyword arguments:

* `name`: The name of the depositor
* `email`: The email address of the depositor

#### Example

```ruby
depositor = CrossrefDeposit::Depositor.new(
  name: "Example Press",
  email: "doi@example.com"
)

deposit = CrossrefDeposit::Deposit.new(
  doi_batch_id: "example-20260307-0001",
  depositor: depositor,
  registrant: "Example Press",
  items: [book]
)

deposit.validate # returns an array of error messages, if any
deposit.validate! # raises CrossrefDeposit::ValidationError, if any
```

### Submitting

Create a `CrossrefDeposit::Client` and submit the deposit.

Deposits are **asynchronous**. `#submit` returns once CrossRef queues the file; outcomes are retrieved separately.

```ruby
client = CrossrefDeposit::Client.new(
  login_id: "role", # or "email@address.com/role"
  login_passwd: ENV["CROSSREF_PASSWORD"],
  environment: :production # or :test to submit to test.crossref.org; or set globally with CrossrefDeposit.set_environment
)

receipt = client.submit(deposit.to_xml, file_name: "example-20260307-0001.xml")
receipt.queued? # true if CrossRef accepted the submission
receipt.rejected? # true if CrossRef rejected the submission
```

### Polling for result

CrossRef processes requests asynchronously. In order to fetch the result, you must ping for it (i.e. in a background job) at reasonable intervals.

```ruby
log = client.fetch_result(file_name: "example-20260307-0001.xml")
log.success? # true when every record registered
log.failures # [CrossrefDeposit::SubmissionLog::Record, ...]
```

## Schema & validation

Schema validation (against CrossRef 5.5.0) runs offline.

### Important note

Validation uses Nokogiri, which implements **XSD 1.0**. The CrossRef schema uses a handful of **XSD 1.1** `<xsd:assert>` constraints, which are incompatible with XSD 1.0. As a result, these constraints are removed for local validation. Local validation will therefore catch **as much as possible**, but it's possible for a validation error to get through to CrossRef. In this case, CrossRef, which does implement the XSD 1.1 constraints server-side, will return a validation failure that should be handled.

## Future development

This gem currently registers **books (monographs)**. Future plans include support for:

- Book chapters (`content_item`) and journal articles.
- Resource-only deposits (adding license/relations to existing records).