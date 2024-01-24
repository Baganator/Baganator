#!/usr/bin/python3
import csv

conjured_items = []

with open('ItemSparse.csv', newline='') as f:
    reader = csv.DictReader(f, delimiter=',')
    for row in reader:
        flags = int(row['Flags_0'])
        if flags & 0x2 > 0:
            conjured_items.append(int(row['ID']))

print("Baganator.Constants.AllConjuredItems = {")
for item in conjured_items:
    print(str(item) + ",")
print("}")
