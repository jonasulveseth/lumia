class DocumentsController < ApplicationController
  before_action :set_document, only: %i[show destroy reanalyze]

  def index
    @documents = current_user.documents.recent
  end

  def new
    @document = current_user.documents.new(kind: "lab_result")
  end

  def create
    @document = current_user.documents.new(params.expect(document: %i[title kind taken_on file extracted_text]))
    @document.title = @document.file.filename.base if @document.title.blank? && @document.file.attached?
    if @document.save
      redirect_to @document, notice: t("documents.uploaded")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @measurements = @document.measurements.order(:label)
  end

  def reanalyze
    @document.update!(status: "pending")
    DocumentAnalysisJob.perform_later(@document)
    redirect_to @document, notice: t("documents.reanalyzing")
  end

  def destroy
    @document.destroy
    redirect_to documents_path, status: :see_other, notice: t("flash.deleted")
  end

  private

  def set_document
    @document = current_user.documents.find(params[:id])
  end
end
