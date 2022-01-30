class TagPromptDeployment < ActiveRecord::Base
  belongs_to :tag_prompt
  belongs_to :assignment
  belongs_to :questionnaire
  has_many :answer_tags, dependent: :destroy

  require "time"

  def tag_prompt
    TagPrompt.find(self.tag_prompt_id)
  end

  def get_number_of_taggable_answers(user_id)
    team = Team.joins(:teams_users).where(team_users: {parent_id: self.assignment_id}, user_id: user_id)
    responses = Response.joins(:response_maps).where(response_maps: {reviewed_object_id: self.assignment.id, reviewee_id: team.id})
    questions = Question.where(questionnaire_id: self.questionnaire.id, type: self.question_type)

    unless responses.empty? || questions.empty?
      responses_ids = responses.map(&:id)
      questions_ids = questions.map(&:id)

      answers = Answer.where(question_id: questions_ids, response_id: responses_ids)

      answers = answers.where(conditions: "length(comments) < #{self.answer_length_threshold}" ) unless self.answer_length_threshold.nil?
      return answers.count
    end
    0
  end

  def assignment_tagging_progress
    teams = Team.where(parent_id: self.assignment_id)
    questions = Question.where(questionnaire_id: self.questionnaire.id, type: self.question_type)
    questions_ids = questions.map(&:id)
    user_answer_tagging = []
    unless teams.empty? || questions.empty?
      teams.each do |team|
        if self.assignment.vary_by_round
          responses = []
          1.upto(self.assignment.rounds_of_reviews).each do |round|
            responses += ReviewResponseMap.get_responses_for_team_round(team, round)
          end
        else
          responses = ResponseMap.assessments_for(team)
        end
        responses_ids = responses.map(&:id)
        answers = Answer.where(question_id: questions_ids, response_id: responses_ids)

        answers = answers.select { |answer| answer.comments.length > self.answer_length_threshold } unless self.answer_length_threshold.nil?
        answers_ids = answers.map(&:id)
        teams_users = TeamsUser.where(team_id: team.id)
        users = teams_users.map{ |teams_user| User.find(teams_user.user_id) }

        users.each do |user|
          tags = AnswerTag.where(tag_prompt_deployment_id: self.id, user_id: user.id, answer_id: answers_ids)
          tagged_answers_ids = tags.map(&:answer_id)

          # E2082 Track_Time_Between_Successive_Tag_Assignments
          # Extract time where each tag is generated / modified
          tag_updated_times = tags.map(&:updated_at)
          # tag_updated_times.sort_by{|time_string| Time.parse(time_string)}.reverse
          tag_updated_times.sort_by{|time_string| time_string}.reverse
          number_of_updated_time = tag_updated_times.length
          tag_update_intervals = []
          1.upto(number_of_updated_time -1).each do |i|
            tag_update_intervals.append(tag_updated_times[i] - tag_updated_times[i-1])
          end

          percentage = answers.count.zero? ? "-" : format("%.1f", tags.count.to_f / answers.count * 100)
          not_tagged_answers = answers.select { |answer| !tagged_answers_ids.include?(answer.id) }

          # E2082 Adding tag_update_intervals as information that should be passed
          answer_tagging = VmUserAnswerTagging.new(user, percentage, tags.count, not_tagged_answers.count, answers.count, tag_update_intervals)
          user_answer_tagging.append(answer_tagging)
        end
      end
    end
    user_answer_tagging
  end
end
