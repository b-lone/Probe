import json
from django.http import JsonResponse
from .models import *

def convert_template_to_json(model):
    dict = {
        'id': model.id,
        'name': model.name,
        'sdkTag': model.sdkTag,
        'usageCount': model.usageCount,
        'clipCount': model.clipCount,
        'canReplaceClipCount': model.canReplaceClipCount,
        'previewUrl': model.previewUrl,
        'coverUrl': model.coverUrl,
        'downloadUrl': model.downloadUrl,
        'last_modified': model.last_modified,
    }
    return dict

def template(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            id = data.get('id')
            if not id:
                return JsonResponse({'error': 'Invalid request method'}, status=405)
            
            model = Template(id=id)
    
            name = data.get('name')
            if name:
                model.name = name
    
            sdkTag = data.get('sdkTag')
            if sdkTag is not None:
                model.sdkTag = sdkTag
    
            usageCount = data.get('usageCount')
            if usageCount is not None:
                model.usageCount = usageCount
    
            clipCount = data.get('clipCount')
            if clipCount is not None:
                model.clipCount = clipCount
    
            canReplaceClipCount = data.get('canReplaceClipCount')
            if canReplaceClipCount is not None:
                model.canReplaceClipCount = canReplaceClipCount
    
            previewUrl = data.get('previewUrl')
            if previewUrl:
                model.previewUrl = previewUrl
    
            coverUrl = data.get('coverUrl')
            if coverUrl:
                model.coverUrl = coverUrl
    
            downloadUrl = data.get('downloadUrl')
            if downloadUrl:
                model.downloadUrl = downloadUrl
    
            model.save()
    
            return JsonResponse(convert_template_to_json(model))
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'PUT':
        try:
            data = json.loads(request.body)
            id = data['id']

            model = Template.objects.get(id=id)
            
            name = data.get('name')
            if name:
                model.name = name
    
            sdkTag = data.get('sdkTag')
            if sdkTag is not None:
                model.sdkTag = sdkTag
    
            usageCount = data.get('usageCount')
            if usageCount is not None:
                model.usageCount = usageCount
    
            clipCount = data.get('clipCount')
            if clipCount is not None:
                model.clipCount = clipCount
    
            canReplaceClipCount = data.get('canReplaceClipCount')
            if canReplaceClipCount is not None:
                model.canReplaceClipCount = canReplaceClipCount
    
            previewUrl = data.get('previewUrl')
            if previewUrl:
                model.previewUrl = previewUrl
    
            coverUrl = data.get('coverUrl')
            if coverUrl:
                model.coverUrl = coverUrl
    
            downloadUrl = data.get('downloadUrl')
            if downloadUrl:
                model.downloadUrl = downloadUrl
    
            model.save()
    
            return JsonResponse(convert_template_to_json(model))
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Template.DoesNotExist:
                return JsonResponse({'error': 'Model not found'}, status=404)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'GET':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = Template.objects.get(id=id)
        except Template.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        return JsonResponse(convert_template_to_json(model), safe=False)
    
    elif request.method == 'DELETE':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)

        try:
            model = Template.objects.get(id=id)
        except Template.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)

        model.delete()

        return JsonResponse({'message': 'Model deleted successfully'})
    
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)
    
def templates(request):
    if request.method == 'GET':
        models = Template.objects.all()
        json_list = []
        for model in models:
            json_list.append(convert_template_to_json(model))
        return JsonResponse(json_list, safe=False)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)