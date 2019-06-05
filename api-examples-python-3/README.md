# Python 3 API examples

## Use Case 1
Let's say you have a list of URIs from the Library of Congress Name Authority File (http://id.loc.gov/authorities/names.html).  If you put those URIs into a CSV file, under a column heading of 'authority_id', then you can use the 'snac-lccn-to-ark-csv.py' script to query SNAC and produce an output CSV file that will contain matching SNAC ARK URIs for every LC URI.

Also, if you use ArchivesSpace, then you can export of all of the LC URIs stored in that database with an SQL query like the following:

```SQL
SELECT *
FROM name_authority_id
WHERE authority_id LIKE 'http://id.loc%';
```

The above script can/should certainly be improved, and (if desired), we could also add an example of how to combine the above SQL query into the Python script so that you would not need to provide a CSV file as input.
