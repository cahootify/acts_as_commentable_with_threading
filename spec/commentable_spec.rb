require File.expand_path('./spec_helper', File.dirname(__FILE__))

describe "A class that is commentable" do
  it "can have many root comments" do
    expect(Commentable.new.comment_threads.respond_to?(:each)).to eq(true)
  end

  describe "when is destroyed" do
    before :each do
      @profile = Profile.create!
      @commentable = Commentable.create!
      @comment = Comment.create!(:profile => @profile, :commentable => @commentable, :body => 'blargh')
    end

    it "also destroys its root comments" do
      @commentable.destroy
      expect(Comment.all).not_to include(@comment)
    end

    it "also destroys its nested comments" do
      child = Comment.new(:body => "This is a child", :commentable => @commentable, :profile => @profile)
      child.save!
      child.move_to_child_of(@comment)

      @commentable.destroy
      expect(Comment.all).not_to include(@comment)
      expect(Comment.all).not_to include(child)
    end
  end

  describe "special class finders" do
    before :each do
      @profile = Profile.create!
      @commentable = Commentable.create!
      @other_commentable = Commentable.create!
    end

    describe "#find_comments_for" do
      before :each do
        @comment = Comment.create!(:profile => @profile, :commentable => @commentable, :body => 'blargh')

        @other_comment = Comment.create!(:profile => @profile, :commentable => @other_commentable, :body => 'hello')

        @comments = Commentable.find_comments_for(@commentable)
      end

      it "should return the comments for the passed commentable" do
        expect(@comments).to include(@comment)
      end

      it "should not return the comments for other commentables" do
        expect(@comments).not_to include(@other_comment)
      end
    end

    describe "#find_comments_by_profile" do
      before :each do
        @profile2 = Profile.create!

        @comment = Comment.create!(:profile => @profile, :commentable => @commentable, :body => 'blargh')

        @other_comment = Comment.create!(:profile => @profile2, :commentable => @other_commentable, :body => 'hello')

        @comments = Commentable.find_comments_by_profile(@profile)
      end

      it "should return comments by the passed profile" do
        expect(@comments.all? { |c| c.profile == @profile }).to eq(true)
      end


      it "should not return comments by other profiles" do
        expect(@comments.any? { |c| c.profile != @profile }).to eq(false)
      end
    end
  end

  describe "instance methods" do
    describe "#comments_ordered_by_submitted" do
      before :each do
        @profile = Profile.create!
        @commentable = Commentable.create!
        @other_commentable = Commentable.create!
        @comment = Comment.create!(:profile => @profile, :commentable => @commentable, :body => 'sup')
        @older_comment = Comment.create!(:profile => @profile, :commentable => @commentable, :body => 'sup', :created_at => 1.week.ago)
        @oldest_comment = Comment.create!(:profile => @profile, :commentable => @commentable, :body => 'sup', :created_at => 2.years.ago)
        @other_comment = Comment.create!(:profile => @profile, :commentable => @other_commentable, :body => 'sup')
        @comments = @commentable.comments_ordered_by_submitted
      end

      it "should return its own comments, ordered with the newest first" do
        expect(@comments.all? { |c| c.commentable_type == @commentable.class.to_s and c.commentable_id == @commentable.id }).to eq(true)
        @comments.each_cons(2) { |c, c2| expect(c.created_at).to be > c2.created_at }
      end

      it "should not include comments for other commentables" do
        expect(@comments.any? { |c| c.commentable_type != @commentable.class.to_s or c.commentable_id != @commentable.id }).to eq(false)
      end
    end
  end
end
