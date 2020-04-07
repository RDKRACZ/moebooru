require 'net/http'
require 'RMagick'

include Magick

class CommentController < ApplicationController
  layout "default"
  helper :avatar

  before_action :member_only, :only => [:destroy, :update]
  before_action :janitor_only, :only => [:moderate]
  helper :post

  def edit
    captchaSet()
    @comment = Comment.find(params[:id])
  end

  def update
    captchaSet()

    comment = Comment.find(params[:id])
    if @current_user.has_permission?(comment)
      comment.update_attributes(comment_params)
      respond_to_success("Comment updated", :action => "index")
    else
      access_denied
    end
  end

  def destroy
    captchaSet()

    comment = Comment.find(params[:id])
    if @current_user.has_permission?(comment)
      comment.destroy
      respond_to_success("Comment deleted", :controller => "post", :action => "show", :id => comment.post_id)
    else
      access_denied
    end
  end

  def captcha
    limit_resource('time', 3600)
    tmp_image = Image.new(80, 30) do |c|
      c.background_color= "Transparent"
    end
    drawing = Draw.new
    drawing.annotate(tmp_image, 0, 0, 0, 5, captchaGet()) { |txt|
      txt.gravity = Magick::NorthGravity
      txt.pointsize = 22
      txt.fill = "#800000"
      txt.font_family = 'helvetica'
      txt.font_weight = Magick::BoldWeight
    }
    tmp_image.format = "gif"
    response.headers['Last-Modified'] = Time.now.ctime.to_s
    send_data tmp_image.to_blob, :type => 'image/gif', :disposition => 'inline'
  end

  def create
    if @current_user.is_anonymous?
       response = params.require(:comment)['captcha']
       if response.downcase != captchaGet().downcase
         respond_to_error("CAPTCHA error", { :controller => "post", :action => "show", :id => comment_params[:post_id]}, :status => 401) 
         captchaSet()
         return
       end
    end

    captchaSet()

    if @current_user.is_member_or_lower? && params[:commit] == "Post" && Comment.where(:user_id => @current_user.id).where('created_at > ?', 1.hour.ago).count >= CONFIG["member_comment_limit"]
      # TODO: move this to the model
      respond_to_error("Hourly limit exceeded", { :controller => "post", :action => "show", :id => comment_params[:post_id]}, :status => 421)
      return
    end

    user_id = @current_user.id

    comment = Comment.new(comment_params.merge(:ip_addr => request.remote_ip, :user_id => user_id))
    if params[:commit] == "Post without bumping"
      comment.do_not_bump_post = true
    end

    if comment.save
      respond_to_success("Comment created", :controller => "post", :action => "show", :id => comment.post_id)
    else
      respond_to_error(comment, :action => "index")
    end
  end

  def show
    @comment = Comment.find(params[:id])

    respond_to_list("comment")
  end

  def index
    if params[:format] == "json" || params[:format] == "xml"
      @comments = Comment.where(Comment.generate_sql(params)[:conditions]).order(:id => :desc).paginate(:per_page => 25, :page => page_number)
      respond_to_list("comments")
    else
      @posts = Post.where.not(:last_commented_at => nil).order(:last_commented_at => :desc).paginate(:per_page => 10, :page => page_number).to_a

      comments = []
      @posts.each { |post| comments.push(*post.recent_comments) }

      newest_comment = comments.max { |a, b| a.created_at <=> b.created_at }
      if !@current_user.is_anonymous? && newest_comment && @current_user.last_comment_read_at < newest_comment.created_at
        @current_user.update_attribute(:last_comment_read_at, newest_comment.created_at)
      end

      @posts = @posts.delete_if { |x| !x.can_be_seen_by?(@current_user, :show_deleted => true) }
    end
  end

  def search
    @comments = Comment.order(:id => :desc)

    if params[:query]
      keywords = []
      params[:query].scan(/\S+/).each do |s|
        if s =~ /^(.+?):(.*)/
          search_type = Regexp.last_match[1]
          param = Regexp.last_match[2]
          if search_type == "user"
            user = User.find_by_name(param)
            if user
              @comments = @comments.where(:user_id => user.id)
            else
              @comments = @comments.none
            end
            next
          end
        end

        keywords << s
      end

      if keywords.any?
        @comments = @comments.where("text_search_index @@ TO_TSQUERY(?)", keywords.map(&:to_escaped_for_tsquery).join(" & "))
      end
    else
      @comments = @comments.none
    end

    @comments = @comments.paginate(:per_page => 30, :page => page_number)

    respond_to_list("comments")
  end

  def moderate
    if request.post?
      ids = params["c"].keys
      coms = Comment.where(:id => ids)

      if params["commit"] == "Delete"
        coms.each(&:destroy)
      elsif params["commit"] == "Approve"
        coms.each do |c|
          c.update_attribute(:is_spam, false)
        end
      end

      redirect_to :action => "moderate"
    else
      @comments = Comment.where(:is_spam => true).order(:id => :desc)
    end
  end

  def mark_as_spam
    @comment = Comment.find(params[:id])
    @comment.update_attributes(:is_spam => true)
    respond_to_success("Comment marked as spam", :action => "index")
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :post_id)
  end
end
