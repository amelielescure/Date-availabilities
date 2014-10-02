require 'date'
require 'pry'

class Event < ActiveRecord::Base
  attr_accessible :ends_at, :kind, :starts_at, :weekly_recurring

  def self.availabilities(date) 
    availabilities = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
    openings = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
    openings = Event.where(:kind => "opening")
    
    (date..date+6.day).each_with_index do |date, i|

      availabilities[i][:date] = date
      slots = Array.new

      start_at = DateTime.parse(date.to_s)
      appointments_day = Event.all(:conditions => ['kind = ? and starts_at between ? and ?', "appointment", start_at, start_at + 1.day])
      openings.each do |opening|

        if opening.weekly_recurring == true
          wday = Date.parse(opening.starts_at.to_s).cwday

          if date.wday == wday
            slots = slots_opening(opening.starts_at.strftime("%k:%M"),opening.ends_at.strftime("%k:%M"),slots)
          end

        else

          if opening.starts_at.strftime("%F") == start_at.strftime("%F")
            slots = slots_opening(opening.starts_at.strftime("%k:%M"),opening.ends_at.strftime("%k:%M"),slots)
          end

        end

        #une fois qu'on on a toutes les disponibilités on enlève les évènment appointment
        if !appointments_day.empty?
          appointments_day.each do |appointment|
            [appointment.starts_at].tap do |a|
              while a.last < appointment.ends_at
                slots.delete((a.last).strftime("%-k:%M"))
                a << a.last + 30.minutes 
              end
            end
          end
        end
      end 

      availabilities[i][:slots] = slots
    end
    binding.pry
    return availabilities 
  end

  def self.slots_opening(start_hour, end_hour, slots)
    if !slots.empty? && start_hour < slots.first
      before_slots = [Time.parse(start_hour).strftime("%-k:%M") ]
      while (Time.parse(before_slots.last.to_s) + 30.minutes).strftime("%k:%M")  < end_hour
        before_slots << (Time.parse(before_slots.last.to_s) + 30.minutes).strftime("%-k:%M") 
      end

      slots = before_slots + slots
    else
      slots << Time.parse(start_hour).strftime("%-k:%M") 
      while (Time.parse(slots.last.to_s) + 30.minutes).strftime("%k:%M")  < end_hour
        hour = (Time.parse(slots.last.to_s) + 30.minutes).strftime("%-k:%M") 
        if !slots.include?(hour)
          slots << hour
        end
      end
    end
    return slots
  end

end
