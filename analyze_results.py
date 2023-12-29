#!/usr/bin/env python3

import argparse
import sys
import json
import itertools
from datetime import timedelta
from collections import defaultdict

parser = argparse.ArgumentParser(
  prog='analyze_results',
  description='This script analyzes results from hyperfine benchmark runs')
parser.add_argument('filenames', type=str, nargs='+')
parser.add_argument('--row-field', type=str, required=True, help='Hyperfine parameter name for output rows')
parser.add_argument('--col-field', type=str, required=True, help='Hyperfine parameter name for output columns')
parser.add_argument('--timeout', type=int, required=False, default=9999, help='Number of seconds for which a test is considered timed out')

def format_timespan(seconds, timeout):
    if seconds >= timeout: return 'Timed out'
    hours,remainder = divmod(seconds, 3600)
    minutes,seconds = divmod(remainder, 60)
    hour_str = f'{hours} hours, ' if hours > 0 else ''
    minute_str = f'{minutes} minutes, ' if hours > 0 or minutes > 0 else ''
    return hour_str + minute_str + f'{seconds:.2f} seconds'

def get_results(filenames):
  results = []
  for filename in filenames:
    with open(filename) as f:
      results += json.load(f)["results"]
  return results

# Returns a dict: {param_name: [sorted list of parameter values]}
def get_parameters(results):
  parameters = defaultdict(set)
  for result in results:
      for param_name,param_value in result["parameters"].items():
          parameters[param_name].add(param_value)

  sorted_parameters = {
      key: sorted(list(value)) for key,value in parameters.items()
  }
  return sorted_parameters

def get_sorted_parameter_names(parameters):
   return sorted(parameters.keys())

# Returns a set of parameter names with only one value, with optional exclusions
def get_single_parameters(parameters, exclude=[]):
  return {name: values[0] for name,values in parameters.items() if name not in exclude and len(values) == 1}

# Returns a set of parameter names with more than one value, with optional exclusions
def get_multi_parameters(parameters, exclude=[]):
  return {name for name,values in parameters.items() if name not in exclude and len(values) > 1}

# Returns a dict: {parameter_tuple: result}
# parameter_tuple is a tuple of parameter values ordered by alphabetical parameter name
# result is an unmodified result value from the input JSON
def get_value_dict(results, parameters):
  sorted_parameter_names = get_sorted_parameter_names(parameters)
  value_dict = {}
  for result in results:
    parameter_tuple = tuple(result["parameters"][name] for name in sorted_parameter_names)
    value_dict[parameter_tuple] = result
  return value_dict

def parameter_dict_to_tuple(parameters):
  sorted_parameter_names = get_sorted_parameter_names(parameters)
  return tuple(parameters[name] for name in sorted_parameter_names)

def generate_table(parameters, value_dict, row_field, col_field, timeout, rest = {}):
    paramdict = rest.copy()
    rows = []
    for row_parameter in parameters[row_field]:
        paramdict[row_field] = row_parameter
        cols = []
        for col_parameter in parameters[col_field]:
            paramdict[col_field] = col_parameter
            param_tuple = parameter_dict_to_tuple(paramdict)
            cols.append(format_timespan(value_dict[param_tuple]["mean"], timeout=timeout))
        rows.append(cols)
    return rows

def main():
  args = parser.parse_args()
  results = get_results(args.filenames)
  parameters = get_parameters(results)
  value_dict = get_value_dict(results, parameters)

  rest_parameters = get_single_parameters(parameters, exclude=[args.row_field, args.col_field])
  multi_parameters = get_multi_parameters(parameters, exclude=[args.row_field, args.col_field])
  # We currently only support two varying dimensions
  assert(not multi_parameters)

  rows = generate_table(parameters, value_dict, col_field=args.col_field, row_field=args.row_field, rest=rest_parameters, timeout=args.timeout)
  print('| File | ' + ' | '.join(parameters[args.col_field]) + ' |')
  print('|:-----|' + '|'.join(['----:' for v in range(len(parameters[args.col_field]))]) +  '|')
  for i in range(len(parameters[args.row_field])):
      print(f'| {parameters[args.row_field][i]} | ' + ' | '.join(rows[i]) + ' |')

if __name__ == "__main__":
  main()
