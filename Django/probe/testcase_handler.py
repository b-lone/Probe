import json
from django.http import JsonResponse
from .models import *

def convert_testcase_to_json(test_case):
    template_ids = test_case.templates.values_list('id', flat=True)
    test_case_dict = {
        'id': test_case.id,
        'name': test_case.name,
        'created_at': test_case.created_at,
        'last_modified': test_case.last_modified,
        'template_ids': list(template_ids),
    }
    return test_case_dict

def testcase(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body.decode('utf-8'))
            name = data['name']
            template_ids = data.get('template_ids', [])

            test_case = TestCase(name=name)
            test_case.save()

            for template_id in template_ids:
                try:
                    template = Template.objects.get(id=template_id)
                except Template.DoesNotExist:
                    template = Template(id=template_id)
                    template.save()
                test_case.templates.add(template)
                
            return JsonResponse(convert_testcase_to_json(test_case), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Exception as e:
            return JsonResponse({'message': f'Error creating test cases: {str(e)}'}, status=500)
    
    elif request.method == 'PUT':
        data = json.loads(request.body)
        id = data['id']
        try:
            test_case = TestCase.objects.get(id=id)
        except TestCase.DoesNotExist:
            return JsonResponse({'error': 'Test case not found'}, status=404)

        name = data.get('name')
        template_ids = data.get('template_ids', [])

        if name:
            test_case.name = name
        if template_ids:
            test_case.templates.clear()
            for template_id in template_ids:
                try:
                    template = Template.objects.get(id=template_id)
                except Template.DoesNotExist:
                    template = Template(id=template_id)
                    template.save()
                test_case.templates.add(template)

        test_case.save()

        return JsonResponse(convert_testcase_to_json(test_case), safe=False)
    elif request.method == 'GET':
        id = request.GET.get('id')
        try:
            test_case = TestCase.objects.get(id=id)
        except TestCase.DoesNotExist:
            return JsonResponse({'error': 'Test case not found'}, status=404)
        
        return JsonResponse(convert_testcase_to_json(test_case))
    
    elif request.method == 'DELETE':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            test_case = TestCase.objects.get(id=id)
        except TestCase.DoesNotExist:
            return JsonResponse({'error': 'Test case not found'}, status=404)
        
        test_case.delete()
        return JsonResponse({'message': 'Test case deleted successfully'})
    
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)

    
def testcases(request):
    if request.method == 'GET':
        test_cases = TestCase.objects.all()
        test_case_list = []
        for test_case in test_cases:
            test_case_list.append(convert_testcase_to_json(test_case))
        return JsonResponse(test_case_list, safe=False)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)