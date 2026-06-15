
# Request Moderation Shell

Wave 8A starts the request moderation section with safe host-side preview fixtures.

## Included

- incoming-request model fixture
- host-side incoming-request list preview
- approve action preview
- edit action preview
- reject action preview
- add-all action preview
- singer-match suggestion preview
- duplicate-request detection preview
- per-singer request-limit preview
- host override for request limits preview

## Safety boundary

Wave 8A does not approve real requests, edit real requests, reject real requests, add all requests to a queue, call server APIs, write queue records, write singer records, store personal data, or modify venue defaults.
