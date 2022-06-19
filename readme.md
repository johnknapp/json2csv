### **This is a ruby 2.7.2 script**

1. It retrieves JSON from a URL and writes CSV locally
1. It does basic scrubbing of the JSON
1. It has basic guardrails (malformed URL or JSON)
1. It parses the JSON into a ruby hash
1. It walks the hash, (array by array,) transforms the data and writes CSV rows
1. It retains both the JSON input and CSV output

**Project prep:**
1. Bundle the Gemfile

**Project operation:**

1. Visit the project folder
1. invoke thus: `ruby json2csv.rb <URL>`
1. The JSON and CSV are written to the project folder

**Notes:**

- Didn't bother with parallel operation or background processing
- During json encoding:
  - Stripped multibyte UTF-8 chars
  - Stripped zero-width spaces
- Advent observations / decisions
  - array 1
    - retained objects which don't have code and code type
    - stripped `<U+200B>`
  - array 2
    - is OK
  - array 3
    - retained items which have variance in omitted keys
    - stripped multibyte UTF-8 string `[239, 191, 189]`
  - array 4
    - processed items without gross charge