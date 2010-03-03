module Formtastic
  module NestedEditHelper

    # Renders a partial to generate a HTML template for a nested model in
    # a form. Use this with the addNestedItem JavaScript function to
    # support dynamically adding nested models.
    #
    # For example, given a form builder for a Post, you could call:
    #
    #   generate_nested_model_template(form, :comments)
    #
    # to get a template for a new comment nested model.
    def generate_nested_model_template(form_builder, method, options = {})
      options[:object]  ||= form_builder.object.class.reflect_on_association(method).klass.new
      options[:partial] ||= method.to_s.singularize
      options[:form_builder_local] ||= :f

      form_builder.fields_for(method, options[:object], :child_index => "NEW_RECORD") do |fields|
        render(:partial => options[:partial], :locals => {
            options[:form_builder_local] => fields,
            :has_expanded_preview => true,
          })
      end
    end

    # Render a hidden field to hold the destroy flag for a nested model.
    def remove_link(form, link_text = nil)
      id = form.object_id.abs
      text = link_text.blank? ? image_tag("/images/nested_edit/remove.png", :class => "icon") : link_text
      if form.object.new_record?
        link_to(text, "#", :id => "#{id}", :class=>"remove_link")
      else
        link_to(text, "#", :id => "#{id}", :class => "remove_link") +
          form.hidden_field(:_destroy, :id => "hidden_#{id}")
      end
    end

    def nested_edit builder, association, partial, add_label, preview_proc
      documents = association.to_s
      document = documents.singularize
      javascript = <<-JSCRIPT
      <script type="text/javascript" charset="utf-8">
        <!--
      jQuery(document).ready(function() {
          var template = #{generate_nested_model_template(builder, association, :partial => partial).to_json};
      jQuery("#add_#{document}_link").click(function(event){add_nested_item(event, "#new_#{documents}_container", template)});
      jQuery("##{documents} .remove_link").live('click', function(event){remove_nested_item(event, jQuery(this), "#{document}")});
      jQuery(".toggle_item_form").live('click', function(event){toggle_item_form(event, jQuery(this), "#{document}")});
      });
      -->
        </script>
      JSCRIPT

      items_presentation = []
      builder.semantic_fields_for(association) do |inner_form|
        items_presentation << render(:partial => partial, :locals => {
            :f => inner_form,
            :has_expanded_preview => preview_proc.call(inner_form.object)
          })
      end
    
      javascript + content_tag(:div,
        #      content_tag(:h3, t("#{documents.capitalize}", :scope => [:partials, association])) +

        # The existing item presentation
        items_presentation.join("\n\n") +
        
          # this is where the new elements will appear
        content_tag(:div, "", :id=>"new_#{documents}_container") +

          # add more... link
        link_to(image_tag("/images/nested_edit/add.png", :class => "icon", :title => add_label) +
            " " +
            add_label,
          "#",
          :id => "add_#{document}_link"
        ),
        :id => documents)
    end
  end
end