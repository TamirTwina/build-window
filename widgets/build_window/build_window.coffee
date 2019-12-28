Batman.Filters.dateFormat = (date) ->
  if moment(date).isValid() then moment(date).fromNow() else date

Batman.Filters.durationFormat = (duration) ->
  if /^[0-9]*$/.test(duration) then moment.duration(duration, 'seconds').humanize() else duration

class Dashing.BuildWindow extends Dashing.Widget
  onData: (data) ->
    if data.status == 'Failed'
      $(@node).css('background-color', '#a73737')
    else if data.status == 'Successful'
      if data.theme == "pro"
        $(@node).css('background-color', '#0066C3')
      else
        $(@node).css('background-color', '#2D9B00')
      

  @accessor 'image', ->
    health = @get('health')
    status = @get('status')
    if (health >= 80) 
      if (status == 'Successful') then 'assets/status-80plus.png'
      else 'assets/build_failed_health_ok.png'
    else if (health >= 60) then 'assets/status-60to79.png'
    else if (health >= 40) then 'assets/status-40to59.png'
    else if (health >= 20) then 'assets/status-20to39.png'
    else 'assets/status-00to19.png'

  @accessor 'show-health', ->
    @get('health') >= 0
