require 'json'
require 'net/http'
require 'net/https'

class BoardStatus
  def initialize(unbreak_now, needs_triage, high, normal,low,open_tasks,done_tasks,tasks_to_verify,all_tasks)
    @unbreak_now = unbreak_now
    @needs_triage = needs_triage
    @high = high
    @normal = normal
    @low = low
    @open_tasks = open_tasks
    @tasks_to_verify = tasks_to_verify
    @done_tasks = done_tasks
    @all_tasks = all_tasks
  end
  def unbreak_now
    @unbreak_now
  end
  def needs_triage
    @needs_triage
  end
  def high
    @high
  end
  def normal
    @normal
  end
  def low
    @low
  end
  def open_tasks
    @open_tasks
  end
  def tasks_to_verify
    @tasks_to_verify
  end
  def done_tasks
    @done_tasks
  end
  def all_tasks
    @all_tasks
  end
end

def get_workboard_with_url(url, after , auth = nil)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  if after != 0 then
    new_query_ar = URI.decode_www_form(uri.query || '') << ["after", after]
    uri.query = URI.encode_www_form(new_query_ar)
  end

  request = Net::HTTP::Get.new(uri.request_uri)

  if auth != nil then
    request.basic_auth *auth
  end

  response = http.request(request)
  return JSON.parse(response.body)
end

def get_all_tasks(url) 
  should_fetch = true
  after = 0
  tasks = Array.new()
  while should_fetch 
    data = get_workboard_with_url(url,after)
    should_fetch = false
    tasks_page = data['result']['data']
    tasks.push(*tasks_page)
    if data['result']['cursor']['after'] != nil then
      should_fetch = true
      after = data['result']['cursor']['after']
    end 
  end 
  return tasks
end


def get_status(url) 
  all_tasks = get_all_tasks(url)
  open_tasks = all_tasks.select { |task| ["open","reopened","inprogress","onhold"].include?(task['fields']['status']['value'])}
  unbreak_now = open_tasks.select { |task| task['fields']['priority']['value'] == 100 }
  needs_triage = open_tasks.select { |task| task['fields']['priority']['value'] == 90 }
  high = open_tasks.select { |task| task['fields']['priority']['value'] == 80 }
  normal = open_tasks.select { |task| task['fields']['priority']['value'] == 50 }
  low = open_tasks.select { |task| task['fields']['priority']['value'] < 50 }
  done_tasks = all_tasks.select { |task| ["accepted","duplicate","invalid","notreproduce","patched","wontfix", "resolved"].include?(task['fields']['status']['value'])}
  tasks_to_verify = all_tasks.select { |task| ["resolved"].include?(task['fields']['status']['value'])}
  puts open_tasks.size.to_f
  puts done_tasks.size.to_f
  puts all_tasks.size.to_f
  status = BoardStatus.new(unbreak_now, needs_triage, high, normal,low,open_tasks,done_tasks,tasks_to_verify,all_tasks)
  return status
end

def print_status(status) 
  text = 'Critical: ' + status.unbreak_now.size.to_s + ' ' + 'Triage: ' + status.needs_triage.size.to_s + ' ' + 'High: ' + status.high.size.to_s + ' ' + 'Normal: ' + status.normal.size.to_s + ' ' + 'Low: ' + status.low.size.to_s + ' | ' + status.done_tasks.size.to_s + '/' + status.all_tasks.size.to_s + ' ' + (status.done_tasks.size.to_f / status.all_tasks.size.to_f).round(2).to_s
  return text
end

def progress_report(workboard,sprint_status)
  closed_points = sprint_status.done_tasks.size || 0
  total_points = sprint_status.all_tasks.size || 0 
  if total_points == 0 then
      percentage = 0
      moreinfo = "No sprint currently in progress"
  else
      percentage = ((closed_points.to_f/total_points.to_f )*100.0).ceil.to_i
      moreinfo = "#{closed_points.to_i} / #{total_points.to_i}"
  end
  send_event(workboard['id'], { title: workboard['title'], min: 0, value: percentage, max: 100, moreinfo: moreinfo })
end

def tasks_distribution_report(workboard,sprint_status)
  labels = [ 'Blocker', 'Triage', 'High', 'Normal', 'Low' ]
  data = [
  {
    data: [ 
      sprint_status.unbreak_now.size,
      sprint_status.needs_triage.size, 
      sprint_status.high.size,
      sprint_status.normal.size,
      sprint_status.low.size,
    ],
    backgroundColor: [
    '#da49be',
    '#8e44ad',
    '#c0392b',
    '#e67e22',
    '#f1c40f'
    ]
  },]
  options = { }

  send_event(workboard['id']+'-doughnutchart', { labels: labels_with_numbers(labels,sprint_status), datasets: data, options: options })
end

def labels_with_numbers (labels,sprint_status)
  return [ 
    "#{sprint_status.unbreak_now.size} #{labels[0]}",
    "#{sprint_status.needs_triage.size} #{labels[1]}",
    "#{sprint_status.high.size} #{labels[2]}",
    "#{sprint_status.normal.size} #{labels[3]}",
    "#{sprint_status.low.size} #{labels[4]} "
  ]
end


SCHEDULER.every '30s' do
    Config::WORKBOARD_LIST.each do |workboard|
        sprint_status = get_status(workboard['url'])

        progress_report(workboard,sprint_status)
        tasks_distribution_report(workboard,sprint_status)
    end
end