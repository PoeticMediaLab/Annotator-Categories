#
# A plugin for Annotator to allow users to categorize annotations
#
# Copyright (C) 2015 Michael Widner, Lacuna Stories
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Annotator.Plugin.Categories extends Annotator.Plugin
  options:
    categories: []
    categoryColorClasses: {}
    categoryClass: "annotator-category"
    classForSelectedCategory : "annotator-category-selected"
    emptyCategory: "Highlight"
    annotatorHighlight: 'span.annotator-hl'

  events:
    '.annotator-category click' : "changeSelectedCategory"
    'annotationEditorSubmit'    : "saveCategory"
    'annotationEditorShown'     : "highlightSelectedCategory"
    'annotationsLoaded'         : 'changeHighlightColors'

  # The field element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  field: null

  # The input element added to the Annotator.Editor wrapped in jQuery. Cached to
  # save having to recreate it everytime the editor is displayed.
  input: null

  widthSet: false

  # Public: Initialises the plugin and adds categories field wrapper to annotator wrapper (editor and viewer)
  # Returns nothing.
  pluginInit: ->
    return unless Annotator.supported()
    @options.categoryColorClasses[@options.emptyCategory] = @options.categoryClass + '-none'
    @field = @annotator.editor.addField({
      label: Annotator._t('Category')
      options: @options
    })

    # Add support for touch devices
    $(document).delegate(".annotator-category", "tap", preventDefault: false, @changeSelectedCategory)

    @annotator.viewer.addField({
      load: @updateViewer
      options: @options
    })

    @input = $(@field).find(':input')

  constructor: (element, options) ->
    super element, options
    @element = element

  changeHighlightColors: (annotations) ->
    # Update the highlight colors for all categorized annotations
    # Called after all annotations loaded
    i = 0
    for category in @options.category
      cssClass = @options.categoryClass + '-' + i
      @options.categoryColorClasses[category] = cssClass
      i++
    for annotation in annotations
      # check if category is empty
      if !annotation.category? or !annotation.category.length
        annotation.category = @options.emptyCategory
      for highlight in annotation.highlights
        $(highlight).addClass(@options.categoryColorClasses[annotation.category])

  setSelectedCategory: (currentCategory) ->
    # Change the selected category in the editor window
    # clear any selection
    $(@field).find('.annotator-category').removeClass @options.classForSelectedCategory
    # add CSS to new selection
    $(@field).find('.annotator-category:contains(' + currentCategory + ')').addClass @options.classForSelectedCategory

  updateViewer: (field, annotation) ->
    # On mouseover, gets the annotation object
    # For displaying mouseover data
    field = $(field)
    field.addClass(@options.categoryClass).html(@options.emptyCategory)
    # if !annotation.category?
    #   annotation.category = @options.emptyCategory
    if annotation.category? and annotation.category.length > 0
      field.addClass(@options.categoryClass).html(annotation.category)
      if annotation.category in @options.category
        field.addClass(@options.categoryColorClasses[annotation.category])

  changeSelectedCategory: (event) =>
    # HTML contains the string with the name of the category
    category = $(event.target).html()
    @setSelectedCategory category

  saveCategory: (event, annotation) ->
    # Find currently selected category; grab the string and save it
    # We prepend the . to tell jQuery this is a class we're seeking
    annotation.category = $(@field).find('.' + @options.classForSelectedCategory).html()
    if annotation.text? and annotation.text.length > 0 and !annotation.category?
      # TODO: force a choice
      window.alert('You did not choose a category, so the default has been chosen.')
      annotation.category = @options.category[0]  # default is first category
    if !annotation.category? or !annotation.text
      annotation.category = @options.emptyCategory
    @changeHighlightColors([annotation])

  highlightSelectedCategory: (event, annotation) ->
    # when editor first shown
    if !annotation.category?
      annotation.category = @options.emptyCategory

    categoryHTML = ""
    for category in @options.category
      categoryHTML += '<span class="' + @options.categoryClass
      categoryHTML += ' ' + @options.categoryColorClasses[category] + '">'
      categoryHTML += category
      categoryHTML += '</span>'
    $(@field).html(categoryHTML)

    if not @widthSet
      # Only set the width once
      @widthSet = true
      totalWidth = 5  # for a tiny bit of extra padding
      # Sum up widths of each category.
      $("span.annotator-category").each (index) ->
        totalWidth += parseInt($(this).outerWidth(true), 10)
        return
      # Set widget width
      $(".annotator-editor .annotator-widget").width totalWidth

    @setSelectedCategory(annotation.category)
