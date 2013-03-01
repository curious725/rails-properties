require 'spec_helper'

describe "Defaults" do
  it "should be stored for simple class" do
    Account.default_settings.should eq(:portal => {})
  end

  it "should be stored for parent class" do
    User.default_settings.should eq(:dashboard => { :theme => 'blue', :view => 'monthly', :filter => false }, :calendar => { :scope => 'company'})
  end
  
  it "should be stored for child class" do
    GuestUser.default_settings.should eq(:dashboard => { :theme => 'red', :view => 'monthly', :filter => false })
  end
end

describe "Getter/Setter" do
  let(:account) { Account.new :subdomain => 'foo' }

  it "should handle method syntax" do
    account.settings(:portal).enabled = true
    account.settings(:portal).template = 'black'

    account.settings(:portal).enabled.should eq(true)
    account.settings(:portal).template.should eq('black')
  end
  
  it "should return nil for not existing key" do
    account.settings(:portal).foo.should eq(nil)
  end
end

describe 'Objects' do
  context 'without defaults' do
    let(:account) { Account.new :subdomain => 'foo' }

    it 'should have blank settings' do
      account.settings(:portal).should eq(OpenStruct.new)
    end

    it 'should not add settings' do
      account.save!
      RailsSettings::SettingObject.count.should eq(0)
    end

    it "should save object with settings" do
      account.settings(:portal).premium = true
      account.settings(:portal).fee = 42.5
      account.save!

      account.reload
      account.settings(:portal).premium.should eq(true)
      account.settings(:portal).fee.should eq(42.5)
      
      RailsSettings::SettingObject.count.should eq(1)
      RailsSettings::SettingObject.first.value.should == { :premium => true, :fee => 42.5 }
    end
  end

  context 'with defaults' do
    let(:user) { User.new :name => 'Mr. Brown' }

    it 'should have default settings' do
      user.settings(:dashboard).theme.should eq('blue')
      user.settings(:dashboard).view.should eq('monthly')
      user.settings(:dashboard).filter.should eq(false)
      user.settings(:calendar).scope.should eq('company')
    end
    
    it 'should have default settings after changing one' do
      user.settings(:dashboard).theme = 'gray'
      
      user.settings(:dashboard).theme.should eq('gray')
      user.settings(:dashboard).view.should eq('monthly')
      user.settings(:dashboard).filter.should eq(false)
      user.settings(:calendar).scope.should eq('company')
    end

    it "should overwrite settings" do
      user.settings(:dashboard).theme = 'brown'
      user.settings(:dashboard).filter = true
      user.save!

      user.reload
      user.settings(:dashboard).theme.should eq('brown')
      user.settings(:dashboard).filter.should eq(true)

      RailsSettings::SettingObject.count.should eq(1)
      RailsSettings::SettingObject.first.value.should == { :theme => 'brown', :view => 'monthly', :filter => true }
    end

    it "should merge settings with defaults" do
      user.settings(:dashboard).theme = 'brown'
      user.save!

      user.reload
      user.settings(:dashboard).theme.should eq('brown')
      user.settings(:dashboard).filter.should eq(false)

      RailsSettings::SettingObject.count.should eq(1)
      RailsSettings::SettingObject.first.value.should == { :theme => 'brown', :view => 'monthly', :filter => false }
    end
  end
end

describe "Object without settings" do
  let!(:user) { User.create! :name => 'Mr. White' }
  
  it "should have no setting objects" do
    RailsSettings::SettingObject.count.should eq(0)
  end

  it "should update settings" do
    user.update_settings! :dashboard, :smart => true

    user.reset_settings
    user.settings(:dashboard).smart.should eq(true)
  end

  it "should reset settings" do
    expect {
      user.settings(:dashboard).dummy = 42
      user.reset_settings
      user.settings(:dashboard).dummy.should eq(nil)
    }.not_to change(RailsSettings::SettingObject, :count)
  end

  it "should destroy settings with nil" do
    expect {
      user.settings = nil
      user.save!
    }.to_not change(RailsSettings::SettingObject, :count)
  end
end

describe "Object with settings" do
  let!(:user) do
    User.create! :name => 'Mr. White' do |user|
      user.settings(:dashboard).theme = 'white'
      user.settings(:calendar).scope = 'all'
    end
  end
  
  it "should have two setting objects" do
    RailsSettings::SettingObject.count.should eq(2)
  end

  it "should update settings" do
    user.update_settings! :dashboard, :smart => true

    user.reset_settings
    user.settings(:dashboard).smart.should eq(true)
    user.settings(:dashboard).theme.should eq('white')
    user.settings(:calendar).scope.should eq('all')
  end
  
  it "should reset settings" do
    expect {
      user.settings(:dashboard).dummy = 42
      user.reset_settings
      user.settings(:dashboard).dummy.should eq(nil)
    }.not_to change(RailsSettings::SettingObject, :count)
  end

  it "should destroy settings with nil" do
    expect {
      user.settings = nil
      user.save!
    }.to change(RailsSettings::SettingObject, :count).by(-2)
  end
end
