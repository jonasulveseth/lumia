class EntriesController < ApplicationController
  def index
    @area_key = params[:area].presence_in(Area.keys)
    scope = current_user.entries.recent
    scope = scope.in_area(@area_key) if @area_key
    @entries = scope.limit(100)
    @entry = current_user.entries.new
  end

  def create
    @entry = current_user.entries.new(params.expect(entry: [ :body, :kind, :occurred_at, area_keys: [] ]))
    @entry.area_keys = @entry.area_keys.compact_blank & Area.keys
    if @entry.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back_or_to entries_path, notice: t("entries.created") }
      end
    else
      redirect_back_or_to entries_path, alert: @entry.errors.full_messages.to_sentence
    end
  end

  def destroy
    current_user.entries.find(params[:id]).destroy
    redirect_back_or_to entries_path, status: :see_other
  end
end
