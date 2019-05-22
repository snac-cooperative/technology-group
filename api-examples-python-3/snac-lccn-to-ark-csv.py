#!/usr/bin/python3

import csv, json, requests

def open_csv():
    '''This function opens a csv file in DictReader mode'''
    input_csv = input('Please enter path to CSV: ')
    file = open(input_csv, 'r', encoding='utf-8')
    return csv.DictReader(file)


def get_snac_ark_from_csv():
    csvinput = open_csv()
    '''SNAC API endpoint'''
    base_url = "http://api.snaccooperative.org/"
    headers = {'Content-type': 'application/json','Accept': 'text/plain'}

    '''Right now, the output filename is hardcoded below as snac-sample-output.csv.
    It will only include two columns: the URI that was searched for within SNAC,
    and the matching ARK found in SNAC, if any.  If no match is found, the resulting cell will be blank.'''
    with open('snac-sample-output.csv', mode='w') as csvoutput:
        fieldnames = ['lc_uri', 'snac_ark']
        writer = csv.DictWriter(csvoutput, lineterminator='\n', fieldnames=fieldnames)
        writer.writeheader()
      
        for row in csvinput:
            try:
                lcnaf_uri = row.get("authority_id")
                data = {'command': 'read','sameas': lcnaf_uri}
                query = requests.put(base_url, data=json.dumps(data), headers=headers).json()
                ark_match = query['constellation']['ark']
                print(ark_match)
                writer.writerow({'lc_uri': lcnaf_uri, 'snac_ark': ark_match})
                
            except Exception as e:
                print(e)
                writer.writerow({'lc_uri': lcnaf_uri, 'snac_ark': ''})
                continue

def main():
    get_snac_ark_from_csv()


if __name__ == '__main__':
    main()
