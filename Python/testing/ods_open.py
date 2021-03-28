from pyexcel_ods import get_data
import sys
import json

data = get_data(sys.argv[1])
print(list(data))
print((json.dumps(data)))
