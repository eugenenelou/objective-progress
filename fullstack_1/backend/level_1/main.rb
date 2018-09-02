require 'json'

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
  progress = 100.0 * (progress_record['value'] - objective['start']) / (objective['target'] - objective['start'])
  result << {'id' => progress_record['id'], 'progress' => progress.round}
end

output = JSON.pretty_generate({'progress_records' => result})
File.write('data/output.json', output)
