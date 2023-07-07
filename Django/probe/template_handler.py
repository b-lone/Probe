import json
from django.http import JsonResponse
from .models import *

def convert_template_to_json(template):
    template_dict = {
        'id': template.id,
        'name': template.name,
        'sdkTag': template.sdkTag,
        'usageCount': template.usageCount,
        'clipCount': template.clipCount,
        'canReplaceClipCount': template.canReplaceClipCount,
        'previewUrl': template.previewUrl,
        'coverUrl': template.coverUrl,
        'downloadUrl': template.downloadUrl,
        'last_modified': template.last_modified,
    }
    return template_dict

def template(request):
    if request.method == 'GET':
        id = request.GET.get('id')

        if not id:
            return JsonResponse({'error': 'Template ID is required'}, status=400)
        
        try:
            template = Template.objects.get(id=id)
        except Template.DoesNotExist:
            return JsonResponse({'error': 'Template not found'}, status=404)
        
        return JsonResponse(convert_template_to_json(template), safe=False)
    elif request.method == 'PUT':
        data = json.loads(request.body)
        id = data['id']

        try:
            template = Template.objects.get(id=id)
        except Template.DoesNotExist:
            return JsonResponse({'error': 'Template not found'}, status=404)
        
        name = data.get('name')
        if name:
            template.name = name

        sdkTag = data.get('sdkTag')
        if sdkTag is not None:
            template.sdkTag = sdkTag

        usageCount = data.get('usageCount')
        if usageCount is not None:
            template.usageCount = usageCount

        clipCount = data.get('clipCount')
        if clipCount is not None:
            template.clipCount = clipCount

        canReplaceClipCount = data.get('canReplaceClipCount')
        if canReplaceClipCount is not None:
            template.canReplaceClipCount = canReplaceClipCount

        previewUrl = data.get('previewUrl')
        if previewUrl:
            template.previewUrl = previewUrl

        coverUrl = data.get('coverUrl')
        if coverUrl:
            template.coverUrl = coverUrl

        downloadUrl = data.get('downloadUrl')
        if downloadUrl:
            template.downloadUrl = downloadUrl

        template.save()

        return JsonResponse(convert_template_to_json(template))
    
    elif request.method == 'DELETE':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'Template ID is required'}, status=400)

        try:
            template = Template.objects.get(id=id)
        except Template.DoesNotExist:
            return JsonResponse({'error': 'Template not found'}, status=404)

        template.delete()

        return JsonResponse({'message': 'Template deleted successfully'})
    
    elif request.method == 'POST':
        data = json.loads(request.body)
        id = data.get('id')
        if not id:
            return JsonResponse({'error': 'Invalid request method'}, status=405)
        
        template = Template(id=id)

        name = data.get('name')
        if name:
            template.name = name

        sdkTag = data.get('sdkTag')
        if sdkTag is not None:
            template.sdkTag = sdkTag

        usageCount = data.get('usageCount')
        if usageCount is not None:
            template.usageCount = usageCount

        clipCount = data.get('clipCount')
        if clipCount is not None:
            template.clipCount = clipCount

        canReplaceClipCount = data.get('canReplaceClipCount')
        if canReplaceClipCount is not None:
            template.canReplaceClipCount = canReplaceClipCount

        previewUrl = data.get('previewUrl')
        if previewUrl:
            template.previewUrl = previewUrl

        coverUrl = data.get('coverUrl')
        if coverUrl:
            template.coverUrl = coverUrl

        downloadUrl = data.get('downloadUrl')
        if downloadUrl:
            template.downloadUrl = downloadUrl

        template.save()

        return JsonResponse(convert_template_to_json(template))
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)
    
def templates(request):
    if request.method == 'GET':
        templates = Template.objects.all()

        template_list = []
        for template in templates:
            template_list.append(convert_template_to_json(template))

        return JsonResponse(template_list, safe=False)
    else:   
        return JsonResponse({'error': 'Invalid request method'}, status=405)