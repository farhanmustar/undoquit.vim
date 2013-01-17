require 'spec_helper'

describe "Undoquit" do
  let(:vim) { @vim }

  # TODO (2013-01-14) Slow!
  def tab_pages
    last_tab_page = vim.command("echo tabpagenr('$')").to_i

    (1 .. last_tab_page).map do |tabnr|
      winnr = vim.command("echo tabpagewinnr(#{tabnr})")
      vim.normal("#{tabnr}gt")
      vim.command("#{winnr}wincmd w")
      vim.command("echo bufname('%')")
    end
  end

  def windows
    last_window = vim.command("echo winnr('$')").to_i

    (1 .. last_window).map do |winnr|
      vim.command("#{winnr}wincmd w")
      vim.command("echo bufname('%')")
    end
  end

  before :each do
    write_file 'one.txt', 'one'
    write_file 'two.txt', 'two'
    write_file 'three.txt', 'three'

    vim.command :tabonly
    vim.command :only
  end

  describe "tabs" do
    before :each do
      vim.edit 'one.txt'
      vim.command 'tabnew two.txt'
      vim.command 'tabnew three.txt'
    end

    specify "simple case" do
      # close tabpage 3 and 1
      vim.command :quit
      vim.command :tabfirst
      vim.command :quit

      # initial state after quitting
      tab_pages.should eq ['two.txt']

      # restore tabpage 1
      vim.command 'Undoquit'
      tab_pages.should eq ['one.txt', 'two.txt']

      # restore tabpage 3
      vim.command 'Undoquit'
      tab_pages.should eq ['one.txt', 'two.txt', 'three.txt']
    end
  end

  describe "splits" do
    before :each do
      vim.edit 'one.txt'
      vim.command 'rightbelow split two.txt'
      vim.command 'rightbelow split three.txt'
    end

    specify "simple case" do
      # close windows 3 and 1
      vim.command '3wincmd w'
      vim.command :quit
      vim.command '1wincmd w'
      vim.command :quit

      # initial state after quitting
      windows.should eq ['two.txt']

      # restore window 1
      vim.command 'Undoquit'
      windows.should eq ['one.txt', 'two.txt']

      # restore window 3
      vim.command 'Undoquit'
      windows.should eq ['one.txt', 'two.txt', 'three.txt']
    end

    specify "quit and undo top window" do
      # close window 1
      vim.command '1wincmd w'
      vim.command :quit

      # initial state after quitting
      windows.should eq ['two.txt', 'three.txt']

      # restore window 1
      vim.command 'Undoquit'
      windows.should eq ['one.txt', 'two.txt', 'three.txt']
    end
  end
end
