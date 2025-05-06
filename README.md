# domain_finder

## Overview

**domain_finder** is an application designed to help users search for and discover available domain names based on keywords, patterns, or specific criteria. It streamlines the process of finding the perfect domain for your business, project, or personal use.

## Features

- Search for available domain names using keywords
- Filter domains by extension (e.g., .com, .net, .org)
- Bulk domain availability checking
- Suggestions for similar or alternative domain names
- Export results to CSV or JSON

## Tech Stack

- Language/Framework: [e.g., Ruby on Rails, Node.js, etc.]
- Dependencies: [e.g., rspec, simplecov, jest, etc.]

## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/domain_finder.git
    cd domain_finder
    ```

2. Install dependencies:
    ```bash
    # For Ruby
    bundle install

    # For Node.js
    npm install
    ```

3. Set up environment variables:
    - Create a `.env` file and add any required API keys or configuration.

4. Run the app:
    ```bash
    # For Ruby
    rails server

    # For Node.js
    npm start
    ```

## Testing & 100% Code Coverage

We require 100% code coverage for all code merged into the main branch.

### Ruby (RSpec + SimpleCov)

- Run the test suite with coverage:
    ```bash
    bundle exec rspec
    ```
- SimpleCov will generate a coverage report in the `coverage/` directory.
- All code must be covered by tests. PRs with less than 100% coverage will not be accepted.

### Node.js (Jest)

- Run the test suite with coverage:
    ```bash
    npm test -- --coverage
    ```
- Jest will generate a coverage report in the `coverage/` directory.
- All code must be covered by tests. PRs with less than 100% coverage will not be accepted.

### Viewing Coverage

Open the generated `coverage/index.html` in your browser to see detailed coverage reports.

## Usage

- Access the application at `http://localhost:PORT`
- Enter your desired keywords or criteria
- View and export available domain names

## Configuration

- API keys for domain lookup services may be required (e.g., Namecheap, GoDaddy, etc.)
- Customize search settings in the `config` file

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Create a new Pull Request

## License

[MIT](LICENSE) or your preferred license.

## Contact

For questions or support, please contact [your email or GitHub].
