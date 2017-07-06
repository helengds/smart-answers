module SmartAnswer
  class PayLeaveForParentsFlow < Flow
    def define
      start_page_content_id "1f6b4ecc-ce2c-488a-b9c7-b78b3bba5598"
      flow_content_id "177cde4d-e52f-4629-bbbe-ec85a18ed944"
      name "pay-leave-for-parents"
      status :published
      satisfies_need "101018"

      multiple_choice :two_carers do
        option "yes"
        option "no"

        on_response do |response|
          self.calculator = Calculators::PayLeaveForParentsCalculator.new
          calculator.two_carers = response
        end

        next_node do
          outcome :due_date
        end
      end

      date_question :due_date do
        on_response do |response|
          calculator.due_date = response
        end

        next_node do
          outcome :employment_status_of_mother
        end
      end

      multiple_choice :employment_status_of_mother do
        option "employee"
        option "worker"
        option "self-employed"
        option "unemployed"

        on_response do |response|
          calculator.employment_status_of_mother = response
        end

        next_node do
          if calculator.two_carers?
            question :employment_status_of_partner
          else
            case calculator.employment_status_of_mother
            when 'employee', 'worker'
              question :mother_started_working_before_continuity_start_date
            when 'self-employed', 'unemployed'
              question :mother_worked_at_least_26_weeks
            end
          end
        end
      end

      multiple_choice :employment_status_of_partner do
        option "employee"
        option "worker"
        option "self-employed"
        option "unemployed"

        on_response do |response|
          calculator.employment_status_of_partner = response
        end

        next_node do
          case calculator.employment_status_of_mother
          when 'employee', 'worker'
            question :mother_started_working_before_continuity_start_date
          when 'self-employed', 'unemployed'
            question :mother_worked_at_least_26_weeks
          end
        end
      end

      multiple_choice :mother_started_working_before_continuity_start_date do
        option "yes"
        option "no"

        on_response do |response|
          calculator.mother_started_working_before_continuity_start_date = response
        end

        next_node do
          outcome :mother_still_working_on_continuity_end_date
        end
      end

      multiple_choice :mother_still_working_on_continuity_end_date do
        option "yes"
        option "no"

        on_response do |response|
          calculator.mother_still_working_on_continuity_end_date = response
        end

        next_node do
          outcome :mother_salary
        end
      end

      salary_question :mother_salary do
        next_node do
          outcome :mother_earned_more_than_lower_earnings_limit
        end
      end

      multiple_choice :mother_earned_more_than_lower_earnings_limit do
        option "yes"
        option "no"

        on_response do |response|
          calculator.mother_earned_more_than_lower_earnings_limit = response
        end

        next_node do
          if calculator.mother_continuity? && calculator.mother_lower_earnings?
            if calculator.two_carers?
              case calculator.employment_status_of_partner
              when 'employee', 'worker'
                question :partner_started_working_before_continuity_start_date
              when 'self-employed', 'unemployed'
                if calculator.due_date >= Date.parse('2015-04-05')
                  question :partner_worked_at_least_26_weeks
                elsif calculator.due_date < Date.parse('2015-04-05')
                  if calculator.employment_status_of_mother == 'employee'
                    outcome :outcome_mat_leave_mat_pay
                  elsif calculator.employment_status_of_mother == 'worker'
                    outcome :outcome_mat_pay
                  end
                end
              end
            else
              if calculator.employment_status_of_mother == 'employee'
                outcome :outcome_mat_leave_mat_pay
              elsif calculator.employment_status_of_mother == 'worker'
                outcome :outcome_mat_pay
              end
            end
          else
            question :mother_worked_at_least_26_weeks
          end
        end
      end

      multiple_choice :mother_worked_at_least_26_weeks do
        option "yes"
        option "no"

        on_response do |response|
          calculator.mother_worked_at_least_26_weeks = response
        end

        next_node do
          outcome :mother_earned_at_least_390
        end
      end

      multiple_choice :mother_earned_at_least_390 do
        option "yes"
        option "no"

        on_response do |response|
          calculator.mother_earned_at_least_390 = response
        end

        next_node do
          if calculator.two_carers?
            if calculator.mother_earnings_employment?
              question :salary_1_66_weeks
            elsif %w(employee worker).include?(calculator.employment_status_of_partner)
              question :partner_started_working_before_continuity_start_date
            elsif %w(self-employed unemployed).include?(calculator.employment_status_of_partner)
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_continuity? && calculator.due_date >= Date.parse('2015-04-05')
                  question :partner_worked_at_least_26_weeks
                elsif calculator.mother_still_working_on_continuity_end_date == 'yes'
                  outcome :outcome_mat_leave
                elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                  outcome :outcome_birth_nothing
                end
              elsif %w(worker self-employed).include?(calculator.employment_status_of_mother)
                outcome :outcome_birth_nothing
              elsif calculator.employment_status_of_mother == 'unemployed'
                if calculator.employment_status_of_partner == 'self-employed'
                  outcome :outcome_mat_allowance_14_weeks
                elsif calculator.employment_status_of_partner == 'unemployed'
                  outcome :outcome_birth_nothing
                end
              end
            end
          else
            if calculator.mother_earnings_employment?
              question :salary_1_66_weeks
            elsif calculator.employment_status_of_mother == 'employee'
              if calculator.mother_still_working_on_continuity_end_date == 'yes'
                outcome :outcome_mat_leave
              elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                outcome :outcome_single_birth_nothing
              end
            elsif %w(worker self-employed unemployed).include?(calculator.employment_status_of_mother)
              outcome :outcome_single_birth_nothing
            end
          end
        end
      end

      salary_question :salary_1_66_weeks do
        precalculate :earnings_employment_start_date do
          calculator.earnings_employment_start_date
        end

        next_node do
          if calculator.two_carers?
            if %w(employee worker).include?(calculator.employment_status_of_partner)
              question :partner_started_working_before_continuity_start_date
            elsif %w(self-employed unemployed).include?(calculator.employment_status_of_partner)
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_continuity? && calculator.due_date >= Date.parse('2015-04-05')
                  question :partner_worked_at_least_26_weeks
                elsif calculator.mother_still_working_on_continuity_end_date == 'yes'
                  outcome :outcome_mat_allowance_mat_leave
                elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                  outcome :outcome_mat_allowance
                end
              elsif %w(worker self-employed unemployed).include?(calculator.employment_status_of_mother)
                outcome :outcome_mat_allowance
              end
            end
          else
            if calculator.employment_status_of_mother == 'employee'
              if calculator.mother_still_working_on_continuity_end_date == 'yes'
                outcome :outcome_mat_allowance_mat_leave
              elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                outcome :outcome_mat_allowance
              end
            elsif %w(worker self-employed unemployed).include?(calculator.employment_status_of_mother)
              outcome :outcome_mat_allowance
            end
          end
        end
      end

      multiple_choice :partner_started_working_before_continuity_start_date do
        option "yes"
        option "no"

        on_response do |response|
          calculator.partner_started_working_before_continuity_start_date = response
        end

        next_node do
          outcome :partner_still_working_on_continuity_end_date
        end
      end

      multiple_choice :partner_still_working_on_continuity_end_date do
        option "yes"
        option "no"

        on_response do |response|
          calculator.partner_still_working_on_continuity_end_date = response
        end

        next_node do
          outcome :partner_salary
        end
      end

      salary_question :partner_salary do
        next_node do
          outcome :partner_earned_more_than_lower_earnings_limit
        end
      end

      multiple_choice :partner_earned_more_than_lower_earnings_limit do
        option "yes"
        option "no"

        on_response do |response|
          calculator.partner_earned_more_than_lower_earnings_limit = response
        end

        next_node do
          if calculator.employment_status_of_partner == 'employee'
            if calculator.partner_continuity? && calculator.partner_lower_earnings?
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_leave_mat_pay_pat_leave_pat_pay_both_shared_leave_both_shared_pay
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_leave_mat_pay_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
                  end
                elsif calculator.mother_started_working_before_continuity_start_date == 'yes' && calculator.mother_still_working_on_continuity_end_date == 'yes'
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_pay_both_shared_leave_pat_shared_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave_pat_pay_mat_shared_leave
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave_pat_pay_additional_pat_leave
                    end
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'yes'
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_pay_pat_shared_leave_pat_shared_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave_pat_pay
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave_pat_pay_additional_pat_leave
                    end
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_pat_leave_pat_pay_pat_shared_leave_pat_shared_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_pat_leave_pat_pay
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_pat_leave_pat_pay
                    end
                  end
                end
              elsif calculator.employment_status_of_mother == 'worker'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_pay_pat_leave_pat_pay_pat_shared_leave_both_shared_pay
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_pay_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
                  end
                elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_pat_leave_pat_pay_pat_shared_leave_pat_shared_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_pat_leave_pat_pay
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_pat_leave_pat_pay
                    end
                  end
                end
              elsif %w(unemployed self-employed).include?(calculator.employment_status_of_mother)
                if !calculator.mother_earnings_employment?
                  outcome :outcome_pat_leave_pat_pay
                elsif calculator.mother_earnings_employment?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_pat_leave_pat_pay_pat_shared_leave_pat_shared_pay
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
                  end
                end
              end
            elsif calculator.partner_continuity?
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    question :partner_worked_at_least_26_weeks
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_leave_mat_pay_pat_leave_additional_pat_leave
                  end
                elsif calculator.mother_continuity?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    question :partner_worked_at_least_26_weeks
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_additional_pat_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave_additional_pat_leave
                    end
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'yes'
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_shared_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_additional_pat_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave_additional_pat_leave
                    end
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                  if calculator.mother_earnings_employment?
                    if calculator.due_date >= Date.parse('2015-04-05')
                      outcome :outcome_mat_allowance_pat_leave_pat_shared_leave
                    elsif calculator.due_date < Date.parse('2015-04-05')
                      outcome :outcome_mat_allowance_pat_leave_additional_pat_leave
                    end
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_pat_leave
                  end
                end
              elsif calculator.employment_status_of_mother == 'worker'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    question :partner_worked_at_least_26_weeks
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_pay_pat_leave_additional_pat_leave
                  end
                elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                  if calculator.mother_earnings_employment?
                    if calculator.due_date >= Date.parse('2015-04-05')
                      outcome :outcome_mat_allowance_pat_leave_pat_shared_leave
                    elsif calculator.due_date < Date.parse('2015-04-05')
                      outcome :outcome_mat_allowance_pat_leave_additional_pat_leave
                    end
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_pat_leave
                  end
                end
              elsif %w(unemployed self-employed).include?(calculator.employment_status_of_mother)
                if calculator.mother_earnings_employment?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_pat_leave_pat_shared_leave
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_pat_leave_additional_pat_leave
                  end
                elsif !calculator.mother_earnings_employment?
                  outcome :outcome_pat_leave
                end
              end
            elsif !calculator.partner_continuity?
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_still_working_on_continuity_end_date == 'yes'
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_continuity?
                      question :partner_worked_at_least_26_weeks
                    else
                      if calculator.mother_earnings_employment?
                        outcome :outcome_mat_allowance_mat_leave
                      elsif !calculator.mother_earnings_employment?
                        outcome :outcome_mat_leave
                      end
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_continuity? && calculator.mother_lower_earnings?
                      outcome :outcome_mat_leave_mat_pay
                    elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                      if calculator.mother_earnings_employment?
                        outcome :outcome_mat_allowance_mat_leave
                      elsif !calculator.mother_earnings_employment?
                        outcome :outcome_mat_leave
                      end
                    end
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_birth_nothing
                  end
                end
              elsif calculator.employment_status_of_mother == 'worker'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    question :partner_worked_at_least_26_weeks
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_pay
                  end
                elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_birth_nothing
                  end
                end
              elsif %w(unemployed self-employed).include?(calculator.employment_status_of_mother)
                if calculator.mother_earnings_employment?
                  outcome :outcome_mat_allowance
                elsif !calculator.mother_earnings_employment?
                  outcome :outcome_birth_nothing
                end
              end
            end
          elsif calculator.employment_status_of_partner == 'worker'
            if calculator.partner_continuity? && calculator.partner_lower_earnings?
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_leave_mat_pay_pat_pay_mat_shared_leave_both_shared_pay
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_leave_mat_pay_pat_pay_additional_pat_pay
                  end
                elsif calculator.mother_continuity?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_pay_mat_shared_leave_pat_shared_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_pay_mat_shared_leave
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_pay_additional_pat_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_pay
                    end
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'yes'
                  if !calculator.mother_earnings_employment?
                    outcome :outcome_mat_leave_pat_pay
                  elsif calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_mat_leave_pat_pay_pat_shared_pay
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_mat_leave_pat_pay_additional_pat_pay
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                  if !calculator.mother_earnings_employment?
                    outcome :outcome_pat_pay
                  elsif calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_pat_pay_pat_shared_pay
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_allowance_pat_pay_additional_pat_pay
                  end
                end
              elsif calculator.employment_status_of_mother == 'worker'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    outcome :outcome_mat_pay_pat_pay_both_shared_pay
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_pay_pat_pay_additional_pat_pay
                  end
                elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_pat_pay_pat_shared_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_pat_pay
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_pat_pay_additional_pat_pay
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_pat_pay
                    end
                  end
                end
              elsif %w(unemployed self-employed).include?(calculator.employment_status_of_mother)
                if calculator.due_date >= Date.parse('2015-04-05')
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance_pat_pay_pat_shared_pay
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_pat_pay
                  end
                elsif calculator.due_date < Date.parse('2015-04-05')
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance_pat_pay_additional_pat_pay
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_pat_pay
                  end
                end
              end
            elsif calculator.partner_continuity?
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    question :partner_worked_at_least_26_weeks
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_leave_mat_pay
                  end
                elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                  if calculator.mother_continuity?
                    if calculator.due_date >= Date.parse('2015-04-05')
                      question :partner_worked_at_least_26_weeks
                    elsif calculator.due_date < Date.parse('2015-04-05') && calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave
                    elsif calculator.due_date < Date.parse('2015-04-05') && !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave
                    end
                  elsif calculator.mother_still_working_on_continuity_end_date == 'yes'
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave
                    end
                  elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_birth_nothing
                    end
                  end
                end
              elsif calculator.employment_status_of_mother == 'worker'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    question :partner_worked_at_least_26_weeks
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_pay_pat_pay_additional_pat_pay
                  end
                elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_birth_nothing
                  end
                end
              elsif %w(unemployed self-employed).include?(calculator.employment_status_of_mother)
                if calculator.mother_earnings_employment?
                  outcome :outcome_mat_allowance
                elsif !calculator.mother_earnings_employment?
                  outcome :outcome_birth_nothing
                end
              end
            elsif !calculator.partner_continuity?
              if calculator.employment_status_of_mother == 'employee'
                if calculator.mother_still_working_on_continuity_end_date == 'yes'
                  if calculator.due_date >= Date.parse('2015-04-05')
                    if calculator.mother_continuity?
                      question :partner_worked_at_least_26_weeks
                    elsif !calculator.mother_continuity?
                      if calculator.mother_earnings_employment?
                        outcome :outcome_mat_allowance_mat_leave
                      elsif !calculator.mother_earnings_employment?
                        outcome :outcome_mat_leave
                      end
                    end
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    if calculator.mother_continuity? && calculator.mother_lower_earnings?
                      outcome :outcome_mat_leave_mat_pay
                    elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                      if calculator.mother_earnings_employment?
                        outcome :outcome_mat_allowance_mat_leave
                      elsif !calculator.mother_earnings_employment?
                        outcome :outcome_mat_leave
                      end
                    end
                  end
                elsif calculator.mother_still_working_on_continuity_end_date == 'no'
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_birth_nothing
                  end
                end
              elsif calculator.employment_status_of_mother == 'worker'
                if calculator.mother_continuity? && calculator.mother_lower_earnings?
                  if calculator.due_date >= Date.parse('2015-04-05')
                    question :partner_worked_at_least_26_weeks
                  elsif calculator.due_date < Date.parse('2015-04-05')
                    outcome :outcome_mat_pay
                  end
                elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_birth_nothing
                  end
                end
              elsif %w(unemployed self-employed).include?(calculator.employment_status_of_mother)
                if calculator.mother_earnings_employment?
                  outcome :outcome_mat_allowance
                elsif !calculator.mother_earnings_employment?
                  outcome :outcome_birth_nothing
                end
              end
            end
          end
        end
      end

      multiple_choice :partner_worked_at_least_26_weeks do
        option "yes"
        option "no"

        on_response do |response|
          calculator.partner_worked_at_least_26_weeks = response
        end

        next_node do
          outcome :partner_earned_at_least_390
        end
      end

      multiple_choice :partner_earned_at_least_390 do
        option "yes"
        option "no"

        on_response do |response|
          calculator.partner_earned_at_least_390 = response
        end

        next_node do
          if calculator.employment_status_of_mother == 'employee'
            if calculator.mother_continuity? && calculator.mother_lower_earnings?
              if calculator.employment_status_of_partner == 'employee'
                if calculator.partner_continuity?
                  if calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                    outcome :outcome_mat_leave_mat_pay_pat_leave_both_shared_leave_mat_shared_pay
                  elsif !calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                    outcome :outcome_mat_leave_mat_pay_pat_leave_pat_shared_leave
                  end
                elsif !calculator.partner_continuity?
                  if calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                    outcome :outcome_mat_leave_mat_pay_mat_shared_leave_mat_shared_pay
                  elsif !calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                    outcome :outcome_mat_leave_mat_pay
                  end
                end
              elsif %w(worker self-employed unemployed).include?(calculator.employment_status_of_partner)
                if calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                  outcome :outcome_mat_leave_mat_pay_mat_shared_leave_mat_shared_pay
                elsif !calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                  outcome :outcome_mat_leave_mat_pay
                end
              end
            elsif !calculator.mother_continuity? || !calculator.mother_lower_earnings?
              if calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                if calculator.employment_status_of_partner == 'employee'
                  if calculator.partner_continuity?
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_both_shared_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave_mat_shared_leave
                    end
                  elsif !calculator.partner_continuity?
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_mat_shared_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_mat_shared_leave
                    end
                  end
                elsif %w(worker self-employed unemployed).include?(calculator.employment_status_of_partner)
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance_mat_leave_mat_shared_leave
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_mat_leave_mat_shared_leave
                  end
                end
              elsif !calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                if calculator.employment_status_of_partner == 'employee'
                  if calculator.partner_continuity?
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_shared_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave_pat_leave
                    end
                  elsif !calculator.partner_continuity?
                    if calculator.mother_earnings_employment?
                      outcome :outcome_mat_allowance_mat_leave
                    elsif !calculator.mother_earnings_employment?
                      outcome :outcome_mat_leave
                    end
                  end
                elsif %w(worker self-employed unemployed).include?(calculator.employment_status_of_partner)
                  if calculator.mother_earnings_employment?
                    outcome :outcome_mat_allowance_mat_leave
                  elsif !calculator.mother_earnings_employment?
                    outcome :outcome_mat_leave
                  end
                end
              end
            end
          elsif calculator.employment_status_of_mother == 'worker'
            if calculator.employment_status_of_partner == 'employee'
              if calculator.partner_continuity?
                if calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                  outcome :outcome_mat_pay_pat_leave_pat_shared_leave_mat_shared_pay
                elsif !calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                  outcome :outcome_mat_pay_pat_leave
                end
              elsif !calculator.partner_continuity?
                if calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                  outcome :outcome_mat_pay_mat_shared_pay
                elsif !calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                  outcome :outcome_mat_pay
                end
              end
            elsif %w(worker self-employed unemployed).include?(calculator.employment_status_of_partner)
              if calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                outcome :outcome_mat_pay_mat_shared_pay
              elsif !calculator.earnings_employment(calculator.partner_earned_at_least_390, calculator.partner_worked_at_least_26_weeks)
                outcome :outcome_mat_pay
              end
            end
          end
        end
      end

      outcome :outcome_birth_nothing
      outcome :outcome_mat_allowance_14_weeks
      outcome :outcome_mat_allowance
      outcome :outcome_mat_allowance_mat_leave
      outcome :outcome_mat_allowance_mat_leave_mat_shared_leave
      outcome :outcome_mat_allowance_mat_leave_pat_leave_additional_pat_leave
      outcome :outcome_mat_allowance_mat_leave_pat_leave_both_shared_leave
      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_pay_both_shared_leave_pat_shared_pay
      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_pay_pat_shared_leave_pat_shared_pay
      outcome :outcome_mat_allowance_mat_leave_pat_leave_pat_shared_leave
      outcome :outcome_mat_allowance_mat_leave_pat_pay_additional_pat_pay
      outcome :outcome_mat_allowance_mat_leave_pat_pay_mat_shared_leave_pat_shared_pay
      outcome :outcome_mat_allowance_mat_leave_pat_pay_pat_shared_pay
      outcome :outcome_mat_allowance_pat_leave_additional_pat_leave
      outcome :outcome_mat_allowance_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
      outcome :outcome_mat_allowance_pat_leave_pat_pay_pat_shared_leave_pat_shared_pay
      outcome :outcome_mat_allowance_pat_leave_pat_shared_leave
      outcome :outcome_mat_allowance_pat_pay_additional_pat_pay
      outcome :outcome_mat_allowance_pat_pay_pat_shared_pay
      outcome :outcome_mat_leave
      outcome :outcome_mat_leave_mat_pay
      outcome :outcome_mat_leave_mat_pay_mat_shared_leave_mat_shared_pay
      outcome :outcome_mat_leave_mat_pay_pat_leave_additional_pat_leave
      outcome :outcome_mat_leave_mat_pay_pat_leave_both_shared_leave_mat_shared_pay
      outcome :outcome_mat_leave_mat_pay_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
      outcome :outcome_mat_leave_mat_pay_pat_leave_pat_pay_both_shared_leave_both_shared_pay
      outcome :outcome_mat_leave_mat_pay_pat_leave_pat_shared_leave
      outcome :outcome_mat_leave_mat_pay_pat_pay_additional_pat_pay
      outcome :outcome_mat_leave_mat_pay_pat_pay_mat_shared_leave_both_shared_pay
      outcome :outcome_mat_leave_mat_shared_leave
      outcome :outcome_mat_leave_pat_leave
      outcome :outcome_mat_leave_pat_leave_additional_pat_leave
      outcome :outcome_mat_leave_pat_leave_mat_shared_leave
      outcome :outcome_mat_leave_pat_leave_pat_pay
      outcome :outcome_mat_leave_pat_leave_pat_pay_additional_pat_leave
      outcome :outcome_mat_leave_pat_leave_pat_pay_mat_shared_leave
      outcome :outcome_mat_leave_pat_pay
      outcome :outcome_mat_leave_pat_pay_mat_shared_leave
      outcome :outcome_mat_pay
      outcome :outcome_mat_pay_mat_shared_pay
      outcome :outcome_mat_pay_pat_leave
      outcome :outcome_mat_pay_pat_leave_additional_pat_leave
      outcome :outcome_mat_pay_pat_leave_pat_pay_additional_pat_leave_additional_pat_pay
      outcome :outcome_mat_pay_pat_leave_pat_pay_pat_shared_leave_both_shared_pay
      outcome :outcome_mat_pay_pat_leave_pat_shared_leave_mat_shared_pay
      outcome :outcome_mat_pay_pat_pay_additional_pat_pay
      outcome :outcome_mat_pay_pat_pay_both_shared_pay
      outcome :outcome_pat_leave
      outcome :outcome_pat_leave_pat_pay
      outcome :outcome_pat_pay
      outcome :outcome_single_birth_nothing
    end
  end
end
