require 'json'
require 'date'

def getFormattedInputData()
  file = File.read('data/input.json')
  data = JSON.parse(file)
  objectives = {}
  progress_records = []
  data['objectives'].each do |objective|
    begin
      objective['start_date'] = Date.parse(objective['start_date'])
      objective['end_date'] = Date.parse(objective['end_date'])
    rescue
      nil
    end
    objective[:milestones] = []
    objectives[objective['id']] = objective
  end
  progress_records = data['progress_records']
  progress_records.each do |progress_record|
    progress_record['date'] = Date.parse(progress_record['date'])
  end
  sorted_milestones = data['milestones'].sort_by { |milestone| milestone['date']}
  sorted_milestones.each do |milestone|
    milestone['date'] = Date.parse(milestone['date'])
    objectives[milestone['objective_id']][:milestones] << milestone
  end

  return { :objectives => objectives, :progress_records => progress_records }
end

def getObjectivesTree(objectives, root_id)
  children = {}
  objectives.each do |id, _|
    children[id] = {}
  end
  objectives.each do |id, objective|
    if(objective.has_key? "parent_id") then
      children[objective['parent_id']][id] = children[id]
    end
  end
  return children[root_id]
end

def getCurrentMilestoneIndex(date, milestones)
  milestones.each_with_index do |milestone, index|
    if(date <= milestone['date']) then
      return index
    end
  end
  return milestones.size
end

def getMilestoneProgress(milestones, milestone_index, date, start_date, end_date)
  milestone_start_date = milestone_index == 0 ? start_date : milestones[milestone_index-1]['date']
  milestone_end_date = milestone_index == milestones.size ? end_date : milestones[milestone_index]['date']
  days_passed_in_milestone = (date - milestone_start_date).to_i
  days_total_in_milestone = (milestone_end_date - milestone_start_date).to_i
  milestone_progress = 1.0 * days_passed_in_milestone / days_total_in_milestone
  return milestone_progress
end

def getMilestonesStartValues(milestones, start, target)
  milestone_start_value = [start]
  milestones.each do |milestone|
    milestone_start_value << milestone['target']
  end
  milestone_start_value << target
  return milestone_start_value
end

def getObjectiveValue(progress_records, date, objective)
  objective_progress_records = progress_records.select { |progress_record| progress_record['objective_id'] == objective['id'] && progress_record['date'] <= date}
                  .sort_by { |progress_record| progress_record['date']}
  return objective_progress_records.size == 0 ? objective['start'] : objective_progress_records[-1]['value']
end

def getExpectedProgress(date, id, objectives, child_ids, progress_records)
  objective = objectives[id]
  if(child_ids.keys.size == 0) then
    if(date >= objective['end_date']) then return 100 end
    start = objective['start']
    target = objective['target']
    milestone_index = getCurrentMilestoneIndex(date, objective[:milestones])

    milestone_progress = getMilestoneProgress(objective[:milestones], milestone_index, date, objective['start_date'], objective['end_date'])

    milestone_start_value = getMilestonesStartValues(objective[:milestones], start, target)

    expected_value = milestone_start_value[milestone_index] + milestone_progress * (milestone_start_value[milestone_index+1] - milestone_start_value[milestone_index])

    expected_progress = 1.0 * (expected_value - start) / (target - start)
    value = getObjectiveValue(progress_records, date, objective)
    progress = 1.0 * (value - start) / (target - start)
    return { :progress => progress, :expected_progress => expected_progress }
  end
  expected_progress = 0
  progress = 0
  coef_sum = 0
  child_ids.each do |child_id, sub_child_ids|
    child_objective = objectives[child_id]
    coef_sum += child_objective['coef']
    result = getExpectedProgress(date, child_id, objectives, sub_child_ids, progress_records)
    child_progress = result[:progress]
    child_expected_progress = result[:expected_progress]
    expected_progress += child_objective['coef'] * child_expected_progress
    progress += child_objective['coef'] * child_progress
  end
  return { :progress => progress / coef_sum, :expected_progress => expected_progress /coef_sum }
end

def getExcesses(objectives, progress_records)
  excesses = []
  progress_records.each do |progress_record|
    objective_id = progress_record['objective_id']
    objectivesTree = getObjectivesTree(objectives, objective_id)
    result = getExpectedProgress(progress_record['date'], objective_id, objectives, objectivesTree, progress_records)
    progress = result[:progress]
    expected_progress = result[:expected_progress]

    excess = 100.0 * (progress - expected_progress) / expected_progress
    excesses << { :id => progress_record['id'], :excess => excess.round }
  end
  return excesses
end

def writeOutput(result)
  sorted_result = result.sort_by { |progress_record| progress_record['id']}
  output = JSON.pretty_generate({'progress_records' => sorted_result})
  File.write('data/output.json', output)
end

data = getFormattedInputData()
objectives = data[:objectives]
progress_records = data[:progress_records]
excesses = getExcesses(objectives, progress_records)
writeOutput(excesses)

# I use the last progress_record value (or the start value if no record) to compute the progress of an objective on a given date
# because a user will only update his progress on unfrequent occasions

# so the value of a progress_record for a parent objective is useless
