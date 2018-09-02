require 'json'
require 'date'

file = File.read('data/input.json')
data = JSON.parse(file)

objectives = data['objectives']
progress_records = data['progress_records']

objectives_by_id = {}
objectives.each do |objective|
  objectives_by_id[objective['id']] = objective
end

result = []
progress_records.each do |progress_record|
  objective = objectives_by_id[progress_record['objective_id']]

  start_date = Date.parse(objective['start_date'])
  current_date = Date.parse(progress_record['date'])
  end_date = Date.parse(objective['end_date'])

  days_passed = (current_date - start_date).to_i
  days_total = (end_date - start_date).to_i

  expected_progress = 1.0 * days_passed / days_total
  progress = 1.0 * (progress_record['value'] - objective['start']) / (objective['target'] - objective['start'])

  excess = 100.0 * (progress - expected_progress) / expected_progress
  result << {'id' => progress_record['id'], 'excess' => excess.round}
end

output = JSON.pretty_generate({'progress_records' => result})
File.write('data/output.json', output)
