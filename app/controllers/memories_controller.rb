# "Vad Lumia vet om dig" – full insyn och kontroll över minnet.
class MemoriesController < ApplicationController
  def index
    @memories = current_user.memories.current.ordered
    @archived_count = current_user.memories.where.not(archived_at: nil).count
    @memory = current_user.memories.new
  end

  def create
    memory = current_user.memories.new(params.expect(memory: %i[content category area_key]).merge(source: "user"))
    if memory.save
      redirect_to memories_path, notice: t("flash.saved")
    else
      redirect_to memories_path, alert: memory.errors.full_messages.to_sentence
    end
  end

  def update
    memory = current_user.memories.find(params[:id])
    memory.update!(params.expect(memory: %i[content pinned category area_key]))
    redirect_to memories_path, notice: t("flash.saved")
  end

  def destroy
    current_user.memories.find(params[:id]).archive!
    redirect_to memories_path, status: :see_other, notice: t("memories.forgotten")
  end
end
