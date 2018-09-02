require 'json'
require 'date'

def getFormattedInputData()
  file = File.read('data/input.json')
  data = JSON.parse(file)
  result = {}
  objectives = {}
  data['objectives'].each do |objective|
    objective['start_date'] = Date.parse(objective['start_date'])
    objective['end_date'] = Date.parse(objective['end_date'])
    objective[:progress_records] = []
    objective[:milestones] = []
    objectives[objective['id']] = objective
  end
  sorted_progress_record = data['progress_records'].sort_by { |progress_record| progress_record['date']}
  sorted_progress_record.each do |progress_record|
    progress_record['date'] = Date.parse(progress_record['date'])
    objectives[progress_record['objective_id']][:progress_records] << progress_record
  end
  sorted_milestones = data['milestones'].sort_by { |milestone| milestone['date']}
  sorted_milestones.each do |milestone|
    milestone['date'] = Date.parse(milestone['date'])
    objectives[milestone['objective_id']][:milestones] << milestone
  end

  return objectives.values
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

def getProgressRecordExcesses(data)
  result = []
  data.each do |objective|
    objective[:progress_records].each do |progress_record|
      date = progress_record['date']
      start = objective['start']
      target = objective['target']
      milestone_index = getCurrentMilestoneIndex(date, objective[:milestones])

      milestone_progress = getMilestoneProgress(objective[:milestones], milestone_index, date, objective['start_date'], objective['end_date'])

      milestone_start_value = getMilestonesStartValues(objective[:milestones], start, target)

      expected_value = milestone_start_value[milestone_index] + milestone_progress * (milestone_start_value[milestone_index+1] - milestone_start_value[milestone_index])

      expected_progress = 1.0 * (expected_value - start) / (target - start)
      progress = 1.0 * (progress_record['value'] - start) / (target - start)

      excess = 100.0 * (progress - expected_progress) / expected_progress
      result << {'id' => progress_record['id'], 'excess' => excess.round}
    end
  end
  return result
end

def writeOutput(result)
  sorted_result = result.sort_by { |progress_record| progress_record['id']}
  output = JSON.pretty_generate({'progress_records' => sorted_result})
  File.write('data/output.json', output)
end

data = getFormattedInputData()
excesses = getProgressRecordExcesses(data)
writeOutput(excesses)
