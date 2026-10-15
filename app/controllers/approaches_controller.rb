class ApproachesController < ApplicationController
  def index
    @choices = current_user.approach_choices.index_by(&:approach_key)
    @groups = Approach.all.group_by(&:area_key)
  end

  # Sätter eller tar bort användarens hållning till ett ramverk.
  def choice
    approach = Approach.find!(params[:id])
    stance = params[:stance].presence_in(ApproachChoice::STANCES)
    choice = current_user.approach_choices.find_or_initialize_by(approach_key: approach.key)
    if stance.nil? || choice.stance == stance && choice.persisted?
      choice.destroy if choice.persisted?
      choice = nil
    else
      choice.update!(stance: stance)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("approach_#{approach.key}", partial: "approaches/approach",
                                                  locals: { approach: approach, choice: choice })
      end
      format.html { redirect_back_or_to approaches_path }
    end
  end
end
